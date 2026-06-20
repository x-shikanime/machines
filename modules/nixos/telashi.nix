{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  # Older Raspberry Pi-class boards still need these cgroup knobs for RKE2.
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      extraUpFlags = [ "--ssh" ];
    };

    fstrim.enable = true;

    gitea-actions-runner.package = pkgs.forgejo-runner;

    nix-serve.enable = true;
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      nix-config.reloadUnits = [ "nix-daemon.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  users.users.telashi = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/telashi";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
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

  knix = {
    enable = true;
    addons = {
      flux = {
        instance.extraConfig.instance.sync = {
          interval = "1m";
          kind = "GitRepository";
          path = "clusters/telashi/overlays/tailnet";
          pullSecret = "";
          ref = "refs/heads/main";
          url = "https://github.com/shikanime/manifests.git";
        };

        operator.extraConfig.web.ingress = {
          enabled = true;
          className = "tailscale";
          annotations."tailscale.com/tags" = "tag:web";
          hosts = [
            {
              host = "telashi-flux";
              paths = [
                {
                  path = "/";
                  pathType = "ImplementationSpecific";
                }
              ];
            }
          ];
          tls = [
            { hosts = [ "telashi-flux" ]; }
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
    tlsSan = [
      "fushi.taila659a.ts.net"
      "minish.taila659a.ts.net"
      "nemishi.taila659a.ts.net"
      "telashi.taila659a.ts.net"
    ];
  };

  sops.secrets.rke2-token.restartUnits = [ "rke2-server.service" ];

  # Expose RKE2 API (9345) and Kubernetes API (6443)
  # as a single Tailscale Service. All 3 aarch64 nodes run the RKE2 API
  # server (HA control plane), so all 3 advertise the service.
  services.tailscale.serve = {
    enable = true;
    services.telashi = {
      endpoints = {
        # RKE2 API
        "tcp:9345" = "tcp://127.0.0.1:9345";
        # Kubernetes API
        "tcp:6443" = "tcp://127.0.0.1:6443";
      };
      advertised = true;
    };
  };
}
