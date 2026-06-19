{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/rke2
  ];

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

  disko.devices = {
    disk.main = {
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
  };

  disko.devices.disk.patchouli = {
    type = "disk";
    device = "/dev/disk/by-label/patchouli";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/patchouli";
      mountOptions = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  hardware = {
    # Intel N150 needs firmware plus userspace graphics/QSV libraries so the
    # Jellyfin pod can use VAAPI/QSV via /dev/dri/renderD128.
    enableRedistributableFirmware = true;

    facter.reportPath = ./facter.json;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        vpl-gpu-rt
      ];
    };
  };

  # Vital for NVMe health and sustained performance
  services.fstrim.enable = true;

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    # Allow Docker runners to connect to cache actions.
    firewall.trustedInterfaces = [ "br-+" ];

    getaddrinfo.precedence = {
      "::1/128" = 50;
      "::/0" = 40;
      "2002::/16" = 30;
      "::/96" = 20;
      "::ffff:0:0/96" = 100;
    };

    hostName = "ashira";
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

  shikanime.rke2 = {
    enable = true;
    extraConfig = {
      nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";
      serverAddr = "https://192.168.1.28:9345";
      tokenFile = config.sops.secrets.rke2-token.path;
    };
    longhorn.enable = true;
    flux = {
      enable = true;
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
      extraUpFlags = [
        "--advertise-routes=10.244.2.0/24,fd00::2:0/112"
        "--ssh"
      ];
    };

    gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.ashira = {
        enable = true;
        name = "ashira";
        tokenFile = config.sops.templates.forgejo-runner-token.path;
        url = "https://forgejo.taila659a.ts.net";
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
      };
    };
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/ashira.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-access-token = { };
      rke2-token = { };
      tailscale-authkey = { };
      forgejo-runner-token = {
        user = "gitea-runner";
        mode = "0440";
      };
    };
    templates = {
      nix-config.content = ''
        extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
      '';
      forgejo-runner-token.content = ''
        TOKEN=${config.sops.placeholder.forgejo-runner-token}
      '';
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
