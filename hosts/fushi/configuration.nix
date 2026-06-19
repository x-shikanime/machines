{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/telashi.nix
  ];

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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    hostName = "fushi";
  };

  sops = {
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/log/containers - - - - /mnt/reimu/log/containers"
    "L+ /var/log/pods - - - - /mnt/reimu/log/pods"
    "L+ /var/swap - - - - /mnt/reimu/swap"
  ];

  knix = {
    nodeIP = "192.168.1.30";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };
}
