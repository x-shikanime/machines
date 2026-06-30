{
  imports = [
    ./node.nix
  ];

  services = {
    knix = {
      enable = false;
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
        traefik.extraConfig.ports = {
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
      };
      # Tailscale IP SANs — required because agents resolve hostnames to IPv6
      # first; without these the load balancer's TLS handshake to the supervisor
      # port (9345) fails with "tls: internal error".
      extraConfig.tls-san =
        let
          ashira = [
            "ashira.taila659a.ts.net"
            "100.71.195.97"
            "fd7a:115c:a1e0::c53a:c362"
          ];
          manash = [
            "manash.taila659a.ts.net"
            "100.74.220.28"
            "fd7a:115c:a1e0::8d3a:dc1c"
          ];
          nalsha = [
            "nalsha.taila659a.ts.net"
            "100.126.72.116"
            "fd7a:115c:a1e0::be3a:4875"
          ];
          nishir = [
            "nishir.taila659a.ts.net"
            "100.80.177.233"
            "fd7a:115c:a1e0::fc3a:b1ea"
          ];
        in
        ashira ++ manash ++ nalsha ++ nishir;
    };

    # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
    tailscale.serve = {
      enable = true;
      services.nishir = {
        advertised = true;
        endpoints = {
          "tcp:6443" = "tcp://127.0.0.1:6443";
          "tcp:9345" = "tcp://127.0.0.1:9345";
        };
      };
    };
  };
}
