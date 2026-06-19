{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/rke2
  ];

  boot = {
    zfs.forceImportRoot = false;

    kernelModules = [
      "br_netfilter"
      "overlay"
      "tcp_bbr"
    ];

    kernelParams = [
      "cgroup_enable=cpuset"
      "cgroup_enable=memory"
      "cgroup_memory=1"
    ];

    kernel.sysctl = {
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;

      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;

      "net.core.default_qdisc" = "fq";
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 7340032;
      "net.core.rmem_max" = 16777216;
      "net.core.somaxconn" = 4096;
      "net.core.wmem_default" = 7340032;
      "net.core.wmem_max" = 16777216;

      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
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

      "net.netfilter.nf_conntrack_max" = 262144;

      "vm.max_map_count" = 262144;

      # NVMe tuning
      "vm.dirty_background_ratio" = 10;
      "vm.dirty_expire_centisecs" = 2000;
      "vm.dirty_ratio" = 20;
      "vm.dirty_writeback_centisecs" = 500;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  disko.devices = {
    disk.flandre = {
      type = "disk";
      device = "/dev/disk/by-label/flandre";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/flandre";
        mountOptions = [
          "nofail"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
          "x-systemd.mount-timeout=30s"
        ];
      };
    };
    disk.nishir = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/nishir";
        mountOptions = [
          "nofail"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
          "x-systemd.mount-timeout=30s"
        ];
      };
    };
    disk.remilia = {
      type = "disk";
      device = "/dev/disk/by-label/remilia";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/remilia";
        mountOptions = [
          "nofail"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
          "x-systemd.mount-timeout=30s"
        ];
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  services.fstrim.enable = true;

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

    hostName = "nemishi";
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

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
      extraUpFlags = [ "--ssh" ];
    };
  };

  shikanime.rke2 = {
    enable = true;
    extraConfig = {
      nodeIP = "192.168.1.27";
      serverAddr = "https://192.168.1.28:9345";
      tokenFile = config.sops.secrets.rke2-token.path;
    };
    longhorn.enable = true;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-config.reloadUnits = [ "nix-daemon.service" ];
      rke2-token.restartUnits = [ "rke2-server.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/nishir/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/nishir/longhorn"
    "L+ /var/log/calico - - - - /mnt/nishir/log/calico"
    "L+ /var/log/containers - - - - /mnt/nishir/log/containers"
    "L+ /var/log/pods - - - - /mnt/nishir/log/pods"
    "L+ /var/swap - - - - /mnt/nishir/swap"
  ];

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
