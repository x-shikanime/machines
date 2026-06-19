{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/telashi.nix
  ];

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

  services.fstrim.enable = true;

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    hostName = "nemishi";
  };

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/nishir/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/nishir/longhorn"
    "L+ /var/log/calico - - - - /mnt/nishir/log/calico"
    "L+ /var/log/containers - - - - /mnt/nishir/log/containers"
    "L+ /var/log/pods - - - - /mnt/nishir/log/pods"
    "L+ /var/swap - - - - /mnt/nishir/swap"
  ];

  knix = {
    nodeIP = "192.168.1.27";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };
}
