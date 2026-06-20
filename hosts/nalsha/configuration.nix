{ config, ... }:

{
  imports = [
    ../../modules/nixos/nishir.nix
    ../../modules/nixos/distributed.nix
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking.hostName = "nalsha";

  knix = {
    nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";
    serverAddr = "https://nishir.taila659a.ts.net:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  services = {
    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.1.0/24,fd00::1:0/112"
    ];

    gitea-actions-runner.instances.nalsha = {
      enable = true;
      name = "nalsha";
      tokenFile = config.sops.templates.forgejo-runner-nalsha-token.path;
      url = "https://forgejo.taila659a.ts.net";
      labels = [
        "docker:docker://node:22-bookworm"
        "nixos-latest:docker://nixos/nix"
        "native:host"
      ];
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/nalsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.forgejo-runner-nalsha-token.restartUnits = [ "forgejo-runner-nalsha.service" ];
    templates.forgejo-runner-nalsha-token.content = ''
      TOKEN=${config.sops.placeholder.forgejo-runner-nalsha-token}
    '';
  };
}
