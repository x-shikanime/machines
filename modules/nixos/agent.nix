{ config, ... }:

{
  imports = [
    ./node.nix
  ];

  services = {
    knix = {
      role = "agent";
      serverAddr = "https://nishir.taila659a.ts.net:9345";
      tokenFile = config.sops.secrets.rke2-token.path;
    };

    # Expose RKE2 API (9345) as a single Tailscale Service.
    tailscale.serve = {
      enable = true;
      services.nishir = {
        advertised = true;
        endpoints = {
          "tcp:9345" = "http://127.0.0.1:9345";
        };
      };
    };
  };

  sops.secrets.rke2-token.restartUnits = [ "rke2-agent.service" ];
}
