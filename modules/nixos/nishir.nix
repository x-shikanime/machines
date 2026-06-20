{
  config,
  pkgs,
  ...
}:

{
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

  knix = {
    addons = {
      flux = {
        instance.extraConfig.instance.sync = {
          interval = "1m";
          kind = "GitRepository";
          path = "clusters/nishir/overlays/tailnet";
          pullSecret = "";
          ref = "refs/heads/main";
          url = "https://github.com/shikanime/manifests.git";
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
    enable = true;
    tlsSan = [
      "ashira.taila659a.ts.net"
      "manash.taila659a.ts.net"
      "nalsha.taila659a.ts.net"
      "nishir.taila659a.ts.net"
    ];
  };

  networking.firewall = {
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

  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      nix-access-token.reloadUnits = [ "nix-daemon.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        addresses = true;
        enable = true;
        workstation = true;
      };
    };

    fstrim.enable = true;

    gitea-actions-runner.package = pkgs.forgejo-runner;

    nix-serve.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      enable = true;
      extraUpFlags = [ "--ssh" ];
      openFirewall = true;
      useRoutingFeatures = "server";
    };
  };

  # Expose RKE2 API (9345), Kubernetes API (6443) and nix-serve (5000) as a single Tailscale Service.
  services.tailscale.serve = {
    enable = true;
    services.nishir = {
      advertised = true;
      endpoints = {
        # Kubernetes API
        "tcp:6443" = "tcp://127.0.0.1:6443";
        # RKE2 API
        "tcp:9345" = "tcp://127.0.0.1:9345";
      };
    };
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    after = [ "network-online.target" ];
    description = "Enable Tailscale UDP GRO forwarding on enp1s0";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off
    '';
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
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

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
