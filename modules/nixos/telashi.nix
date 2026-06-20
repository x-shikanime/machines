{
  imports = [
    ./server.nix
  ];

  # Older Raspberry Pi-class boards still need these cgroup knobs for RKE2.
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

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

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services = {
    fstrim.enable = true;

    # Expose RKE2 API (9345) and Kubernetes API (6443)
    tailscale.serve = {
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
}
