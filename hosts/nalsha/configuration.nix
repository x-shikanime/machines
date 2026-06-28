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
    knix.nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.1.0/24,fd00::1:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/nalsha.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
