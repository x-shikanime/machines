{ config, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/nishir.nix
    ../../modules/nixos/distributed.nix
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking.hostName = "ashira";

  knix = {
    nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  services = {
    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.2.0/24,fd00::2:0/112"
    ];

    gitea-actions-runner.instances.ashira = {
      enable = true;
      name = "ashira";
      tokenFile = config.sops.templates.forgejo-runner-token.path;
      url = "https://forgejo.taila659a.ts.net";
      labels = [
        "docker:docker://node:22-bookworm"
        "nixos-latest:docker://nixos/nix"
        "native:host"
      ];
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/ashira.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      rke2-token.restartUnits = [ "rke2-server.service" ];
      forgejo-runner-token.restartUnits = [ "gitea-runner-ashira.service" ];
    };
    templates.forgejo-runner-token.content = ''
      TOKEN=${config.sops.placeholder.forgejo-runner-token}
    '';
  };
}
