{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Intel N150 needs firmware plus userspace graphics/QSV libraries so the
  # Jellyfin pod can use VAAPI/QSV via /dev/dri/renderD128.
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
          };
        };
      };
    };
  };

  boot = {
    # Kubernetes and Longhorn rely on bridge netfilter and overlayfs; BBR
    # improves WAN/Tailnet flows
    kernelModules = [
      "br_netfilter"
      "overlay"
      "tcp_bbr"
    ];
    kernel.sysctl = {
      # File and Inotify limits - Keep these high for Longhorn, K8s, and Syncthing
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;

      # Bridge networking for CNIs
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;

      # Networking queueing and buffer sizing for overlay networks
      "net.core.default_qdisc" = "fq";
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 7340032;
      "net.core.rmem_max" = 16777216;
      "net.core.somaxconn" = 4096;
      "net.core.wmem_default" = 7340032;
      "net.core.wmem_max" = 16777216;

      # Forwarding, TCP autotuning, and BBR setup
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.enp1s0.rp_filter" = 0;
      "net.ipv4.ip_local_port_range" = "1024 65535";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 15;
      "net.ipv4.tcp_keepalive_time" = 600;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";

      # GC thresholds for ARP/Neighbor tables
      "net.ipv4.neigh.default.gc_thresh1" = 1024;
      "net.ipv4.neigh.default.gc_thresh2" = 2048;
      "net.ipv4.neigh.default.gc_thresh3" = 4096;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;

      # IPv6 Router Advertisement tuning
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;
      "net.ipv6.conf.enp1s0.accept_ra" = 2;
      "net.ipv6.conf.enp1s0.autoconf" = 1;
      "net.ipv6.conf.enp1s0.accept_ra_defrtr" = 0;
      "net.ipv6.conf.enp1s0.accept_ra_pinfo" = 1;
      "net.ipv6.conf.enp1s0.accept_ra_mtu" = 1;
      "net.ipv6.conf.enp1s0.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv6.route.mtu_expires" = 600;
      "net.ipv6.route.min_adv_mss" = 1220;

      # Increase conntrack limits
      "net.netfilter.nf_conntrack_max" = 262144;

      # Required to prevent mmap OOM crashes in memory-mapping heavy pods like Longhorn
      "vm.max_map_count" = 262144;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
    };

    fstrim.enable = true;

    nix-serve.enable = true;

    gitea-actions-runner.package = pkgs.forgejo-runner;
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    description = "Enable Tailscale UDP GRO forwarding on enp1s0";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

  networking.firewall = {
    extraCommands = ''
      iptables -I INPUT -i br+ -j ACCEPT
      iptables -I FORWARD -i br+ -j ACCEPT
      ip6tables -I INPUT -i br+ -j ACCEPT
      ip6tables -I FORWARD -i br+ -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
      ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
    '';
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      nix-access-token.reloadUnits = [ "nix-daemon.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
    '';
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
  };

  knix.flux = {
    enable = lib.mkDefault true;
    instance.extraConfig.instance.sync = lib.mkDefault {
      interval = "1m";
      kind = "GitRepository";
      path = "clusters/nishir/overlays/tailnet";
      pullSecret = "";
      ref = "refs/heads/main";
      url = "https://github.com/shikanime/manifests.git";
    };

    operator.extraConfig.web.ingress = {
      enabled = true;
      className = "tailscale";
      annotations."tailscale.com/tags" = "tag:web";
      hosts = [
        {
          host = "nishir-flux";
          paths = [
            {
              path = "/";
              pathType = "ImplementationSpecific";
            }
          ];
        }
      ];
      tls = [
        { hosts = [ "nishir-flux" ]; }
      ];
    };
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/nishir";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
