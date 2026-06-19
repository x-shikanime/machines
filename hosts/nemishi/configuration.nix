{ modulesPath, ... }:

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

  disko.devices.disk.data = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/data";
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

  networking.hostName = "nemishi";

  knix = {
    enable = true;
    nodeIP = "192.168.1.27";
    serverAddr = "https://192.168.1.28:9345";
  };

  services.fstrim.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/data/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/data/longhorn"
    "L+ /var/log/calico - - - - /mnt/data/log/calico"
    "L+ /var/log/containers - - - - /mnt/data/log/containers"
    "L+ /var/log/pods - - - - /mnt/data/log/pods"
    "L+ /var/swap - - - - /mnt/data/swap"
  ];
}
