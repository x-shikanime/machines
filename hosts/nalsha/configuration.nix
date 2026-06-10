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
      # Raise global descriptor and watch limits for controllers, Syncthing, and
      # large media libraries
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;

      # Let bridged Kubernetes traffic traverse the iptables hooks that CNIs
      # expect
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;

      # Favor low-latency queueing and larger bursts for overlay traffic and
      # busy services
      "net.core.default_qdisc" = "fq";
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 7340032;
      "net.core.rmem_max" = 16777216;
      "net.core.somaxconn" = 4096;
      "net.core.wmem_default" = 7340032;
      "net.core.wmem_max" = 16777216;

      # Keep forwarding and TCP autotuning friendly to k0s, Tailscale, and
      # service fan-out
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
      "net.ipv4.neigh.default.gc_thresh1" = 1024;
      "net.ipv4.neigh.default.gc_thresh2" = 2048;
      "net.ipv4.neigh.default.gc_thresh3" = 4096;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;

      # This host forwards for Kubernetes/Tailscale, but avoids learning a WAN
      # IPv6 default route so outbound clients fall back to IPv4.
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

      # Increase conntrack room for NAT, service meshes, and
      # clustered east-west traffic
      "net.netfilter.nf_conntrack_max" = 262144;

      # Reduce swap thrash and preserve cache behavior on a mixed storage/media
      # node
      "vm.dirty_background_ratio" = 3;
      "vm.dirty_expire_centisecs" = 1000;
      "vm.dirty_ratio" = 10;
      "vm.dirty_writeback_centisecs" = 500;
      "vm.max_map_count" = 262144;
      "vm.page-cluster" = 0;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 200;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
    environment.etc."gai.conf".text = ''
      precedence ::ffff:0:0/96  100
    '';
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

  fileSystems."/mnt/remilia" = {
    label = "remilia";
    fsType = "xfs";
    options = [
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.mount-timeout=30s"
    ];
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    getaddrinfo.precedence = {
      "::1/128" = 50;
      "::/0" = 40;
      "2002::/16" = 30;
      "::/96" = 20;
      "::ffff:0:0/96" = 100;
    };

    hostName = "nalsha";
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
      nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";
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
        "--advertise-routes=10.244.1.0/24,fd00::1:0/112"
        "--ssh"
      ];
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/nalsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-access-token = { };
      rke2-token = { };
      tailscale-authkey = { };
    };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
    '';
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
