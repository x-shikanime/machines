{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
  ];

  boot = {
    zfs.forceImportRoot = false;
  };

  disko.devices = {
    disk.reimu = {
      type = "disk";
      device = "/dev/disk/by-label/reimu";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/reimu";
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

    hostName = "fushi";
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
    nodeIP = "192.168.1.30";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-config.reloadUnits = [ "nix-daemon.service" ];
      rke2-token.restartUnits = [ "rke2-server.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /var/log/containers - - - - /mnt/reimu/log/containers"
    "L+ /var/log/pods - - - - /mnt/reimu/log/pods"
    "L+ /var/swap - - - - /mnt/reimu/swap"
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
