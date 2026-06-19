{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
  ];

  boot = {
    zfs.forceImportRoot = false;

    kernelParams = [
      "cgroup_enable=cpuset"
      "cgroup_enable=memory"
      "cgroup_memory=1"
    ];
  };

  disko.devices = {
    disk.marisa = {
      type = "disk";
      device = "/dev/disk/by-label/marisa";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/marisa";
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

    hostName = "minish";
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

  knix = {
    enable = true;
    nodeIP = "192.168.1.29";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
    longhorn.enable = true;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-config.reloadUnits = [ "nix-daemon.service" ];
      rke2-token.restartUnits = [ "rke2-server.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/marisa/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/marisa/longhorn"
    "L+ /var/log/calico - - - - /mnt/marisa/log/calico"
    "L+ /var/log/containers - - - - /mnt/marisa/log/containers"
    "L+ /var/log/pods - - - - /mnt/marisa/log/pods"
    "L+ /var/swap - - - - /mnt/marisa/swap"
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
