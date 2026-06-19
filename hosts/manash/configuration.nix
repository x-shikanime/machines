{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/nishir.nix
    ../../modules/nixos/k8s.nix
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking.hostName = "manash";

  knix = {
    enable = true;
    nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";
    serverAddr = "https://192.168.1.28:9345";
  };

  services = {
    nix-serve.enable = true;
    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.0.0/24,fd00::/112"
      "--ssh"
    ];

    gitea-actions-runner = {
      instances.manash = {
        enable = true;
        name = "manash";
        tokenFile = config.sops.templates.forgejo-runner-token.path;
        url = "https://forgejo.taila659a.ts.net";
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
      };
    };
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    description = "Enable Tailscale UDP GRO forwarding on enp1s0";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

  sops = {
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.forgejo-runner-token.restartUnits = [ "gitea-runner-manash.service" ];
    templates.forgejo-runner-token.content = ''
      TOKEN=${config.sops.placeholder.forgejo-runner-token}
    '';
  };
}
