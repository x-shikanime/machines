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

  networking.hostName = "nalsha";

  services = {
    gitea-actions-runner.instances = {
      codeberg = {
        enable = true;
        name = "nalsha";
        tokenFile = config.sops.templates.codeberg-runner-token.path;
        url = "https://codeberg.org";
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
      };
      forgejo = {
        enable = true;
        name = "nalsha";
        tokenFile = config.sops.templates.forgejo-runner-token.path;
        url = "https://forgejo.taila659a.ts.net";
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
      };
    };

    knix = {
      nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";
      serverAddr = "https://nishir.taila659a.ts.net:9345";
      tokenFile = config.sops.secrets.rke2-token.path;
    };

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
      rke2-token.restartUnits = [ "rke2-server.service" ];
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
