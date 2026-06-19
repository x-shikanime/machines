{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/telashi.nix
    ../../modules/nixos/k8s.nix
  ];

  boot = {
    zfs.forceImportRoot = false;
  };

  disko.devices.disk.marisa = {
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking.hostName = "minish";

  knix = {
    enable = true;
    nodeIP = "192.168.1.29";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/marisa/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/marisa/longhorn"
    "L+ /var/log/calico - - - - /mnt/marisa/log/calico"
    "L+ /var/log/containers - - - - /mnt/marisa/log/containers"
    "L+ /var/log/pods - - - - /mnt/marisa/log/pods"
    "L+ /var/swap - - - - /mnt/marisa/swap"
  ];
}
