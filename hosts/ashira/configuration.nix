{
  imports = [
    ../../modules/nixos/server.nix
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
  ];

  disko.devices.disk.patchouli = {
    type = "disk";
    device = "/dev/disk/by-label/patchouli";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/patchouli";
      mountOptions = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  hardware.facter.reportPath = ./facter.json;

  networking.hostName = "ashira";

  services = {
    knix.nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.2.0/24,fd00::2:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/ashira.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
