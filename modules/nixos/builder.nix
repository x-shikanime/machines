{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./node.nix
  ];

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      forgejo = {
        enable = true;
        name = config.networking.hostName;
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

  sops = {
    secrets = {
      codeberg-runner-token.restartUnits = [ "codeberg-runner-${config.networking.hostName}.service" ];
      forgejo-runner-token.restartUnits = [ "forgejo-runner-${config.networking.hostName}.service" ];
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

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    useDefaultShell = true;
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
