{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/nishir.nix
    ../../modules/nixos/rke2
  ];

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };

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

  hardware = {
    # Intel N150 needs firmware plus userspace graphics/QSV libraries so the
    # Jellyfin pod can use VAAPI/QSV via /dev/dri/renderD128.
    facter.reportPath = ./facter.json;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        vpl-gpu-rt
      ];
    };
  };

  # Vital for NVMe health and sustained performance
  services.fstrim.enable = true;

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    # Trust Docker bridge traffic for runner job containers.
    firewall = {
      extraCommands = ''
        iptables -I INPUT -i br+ -j ACCEPT
        iptables -I FORWARD -i br+ -j ACCEPT
        ip6tables -I INPUT -i br+ -j ACCEPT
        ip6tables -I FORWARD -i br+ -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
      '';
    };

    hostName = "manash";
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

  shikanime.rke2 = {
    enable = true;
    extraConfig = {
      nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";
    };
    longhorn.enable = true;
    flux = {
      enable = true;
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
  };

  services = {
    nix-serve.enable = true;

    gitea-actions-runner = {
      package = pkgs.forgejo-runner;
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

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      forgejo-runner-token.restartUnits = [ "gitea-runner-manash.service" ];
    };
    templates = {
      forgejo-runner-token.content = ''
        TOKEN=${config.sops.placeholder.forgejo-runner-token}
      '';
    };
  };
}
