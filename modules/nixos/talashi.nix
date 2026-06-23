{ lib, pkgs, ... }:

with lib;

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
            path = "clusters/talashi/overlays/tailnet";
            pullSecret = "";
            ref = "refs/heads/main";
            url = "https://github.com/x-shikanime/manifests.git";
          };

          operator.extraConfig.web.ingress = {
            enabled = true;
            className = "tailscale";
            annotations."tailscale.com/tags" = "tag:web";
            hosts = [
              {
                host = "talashi-flux";
                paths = [
                  {
                    path = "/";
                    pathType = "ImplementationSpecific";
                  }
                ];
              }
            ];
            tls = [
              { hosts = [ "talashi-flux" ]; }
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
        "talashi.taila659a.ts.net"
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

  users.users.talashi = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/talashi";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
