{ lib, ... }:

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

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services = {
    fstrim.enable = true;
  };

  # Tailscale serve with TLS termination (HTTPS) for RKE2 and Kubernetes APIs.
  # The NixOS module (services.tailscale.serve) only supports tcp:<port> which
  # maps to "HTTP": true — no TLS termination. Use systemd oneshot with the
  # tailscale CLI directly as a workaround. Upstream bug: tailscale#18381,
  # nixpkgs#530174.
  systemd.services.tailscale-serve-https = {
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
      ${getExe tailscale} serve --yes --bg --service=svc:talashi-k8s --https=6443 http://127.0.0.1:6443
      ${getExe tailscale} serve --yes --bg --service=svc:talashi-k8s --https=9345 http://127.0.0.1:9345
    '';
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
