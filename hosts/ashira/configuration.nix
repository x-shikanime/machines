{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/server.nix
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

  networking = {
    hostName = "ashira";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.60";
        prefixLength = 24;
      }
    ];
  };

  services = {
    knix = {
      nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";
      labels = [
        "beta.kubernetes.io/instance-type=beelink-eq14"
        "node.kubernetes.io/instance-type=beelink-eq14"
      ];
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.2.0/24,fd00::2:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/ashira.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      forgejo-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
