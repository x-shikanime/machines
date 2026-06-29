{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
    ../../modules/nixos/rpi.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.reimu = {
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

  networking.hostName = "minish";

  services.knix.nodeIP = "192.168.1.29";

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      forgejo-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
