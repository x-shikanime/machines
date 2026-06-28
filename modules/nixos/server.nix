{ config, pkgs, ... }:

{
  imports = [
    ./node.nix
  ];

  services = {
    gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances = {
        codeberg = {
          enable = true;
          name = config.networking.hostName;
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

    knix = {
      enable = true;
      addons = {
        flux = {
          instance.extraConfig.instance.sync = {
            interval = "1m";
            kind = "GitRepository";
            path = "clusters/nishir/overlays/tailnet";
            pullSecret = "";
            ref = "refs/heads/main";
            url = "https://github.com/shikanime-labs/manifests.git";
          };

          operator.extraConfig.web.ingress = {
            enabled = true;
            className = "tailscale";
            annotations."tailscale.com/tags" = "tag:web";
            hosts = [
              {
                host = "nishir-flux";
                paths = [
                  {
                    path = "/";
                    pathType = "ImplementationSpecific";
                  }
                ];
              }
            ];
            tls = [
              { hosts = [ "nishir-flux" ]; }
            ];
          };
        };
        longhorn.extraConfig.recurringJobSelector = {
          enable = true;
          jobList = [
            {
              name = "standard";
              isGroup = true;
            }
          ];
        };
      };
      addons.traefik.extraConfig.ports = {
        syncthing = {
          port = 22000;
          expose.default = true;
          exposedPort = 22000;
          protocol = "TCP";
        };
        syncthing-udp = {
          port = 22000;
          expose.default = true;
          exposedPort = 22000;
          protocol = "UDP";
        };
      };
      tlsSan = [
        "ashira.taila659a.ts.net"
        "manash.taila659a.ts.net"
        "nalsha.taila659a.ts.net"
        "nishir.taila659a.ts.net"
      ];
    };

    # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
    tailscale.serve = {
      enable = true;
      services.nishir = {
        advertised = true;
        endpoints = {
          "tcp:6443" = "http://127.0.0.1:6443";
          "tcp:9345" = "http://127.0.0.1:9345";
        };
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
