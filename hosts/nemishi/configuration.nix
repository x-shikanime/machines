{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/rpi5.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

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

  networking = {
    hostName = "nemishi";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.27";
        prefixLength = 24;
      }
    ];
  };

  services = {
    knix = {
      nodeIP = "192.168.1.27";
      labels = [
        "beta.kubernetes.io/instance-type=rpi5"
        "node.kubernetes.io/instance-type=rpi5"
      ];
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.5.0/24,fd00::5:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
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
