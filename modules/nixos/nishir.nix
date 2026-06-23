{ lib, pkgs, ... }:

with lib;

{
  imports = [
    ./server.nix
  ];

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  disko.devices.disk.main = {
    content = {
      partitions = {
        ESP = {
          content = {
            format = "vfat";
            mountOptions = [ "umask=0077" ];
            mountpoint = "/boot";
            type = "filesystem";
          };
          size = "1G";
          type = "EF00";
        };
        root = {
          content = {
            format = "xfs";
            mountpoint = "/";
            type = "filesystem";
          };
          size = "100%";
        };
      };
      type = "gpt";
    };
    device = "/dev/nvme0n1";
    type = "disk";
  };

  # Intel N150 needs firmware plus userspace graphics/QSV libraries so the
  # Jellyfin pod can use VAAPI/QSV via /dev/dri/renderD128.
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services = {
    fstrim.enable = true;

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
            url = "https://github.com/x-shikanime/manifests.git";
          };

          operator.extraConfig.web.ingress = {
            annotations."tailscale.com/tags" = "tag:web";
            className = "tailscale";
            enabled = true;
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
              isGroup = true;
              name = "standard";
            }
          ];
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
          # Kubernetes API
          "tcp:6443" = "http://127.0.0.1:6443";
          # RKE2 API
          "tcp:9345" = "http://127.0.0.1:9345";
        };
      };
    };
  };

  systemd.services.tailscale-serve-nishir = {
    description = "Expose RKE2 and Kubernetes APIs via Tailscale serve with HTTPS";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = ''
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --https=80 http://127.0.0.1:80
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --https=443 https+insecure://127.0.0.1:443
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --tcp=22000 tcp://127.0.0.1:22000
    '';
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    home = "/home/nishir";
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
