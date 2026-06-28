{ config, ... }:

{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
  ];

  disko.devices.disk.remilia = {
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

  hardware.facter.reportPath = ./facter.json;

  networking.hostName = "nalsha";

  services = {
    knix = {

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.1.0/24,fd00::1:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/nalsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.restartUnits = [ "codeberg-runner-nalsha.service" ];
      forgejo-runner-token.restartUnits = [ "forgejo-runner-nalsha.service" ];
    };
    templates = {
      codeberg-runner-token.content = ''
        TOKEN=${config.sops.placeholder.codeberg-runner-token}
      '';
      forgejo-runner-token.content = ''
        TOKEN=${config.sops.placeholder.forgejo-runner-token}
      '';
    };
  };
}
