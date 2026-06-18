{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

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
    enableRedistributableFirmware = true;

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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
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

  kix.rke2 = {
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
    tailscale.enable = true;
  };

  services.tailscale = {
    authKeyFile = config.sops.secrets.tailscale-authkey.path;
    extraUpFlags = [
      "--advertise-routes=10.244.0.0/24,fd00::/112"
    ];
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      nix-access-token = { };
      tailscale-authkey = { };
    };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
    '';
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/nishir";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
