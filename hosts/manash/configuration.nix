{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/server.nix
    ../../modules/nixos/distributed.nix
  ];

  disko.devices.disk.flandre = {
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

  hardware.facter.reportPath = ./facter.json;

  networking.hostName = "manash";

  services = {
    knix.nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.0.0/24,fd00::/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/manash.enc.yaml;
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
