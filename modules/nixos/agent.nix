{
  imports = [
    ./node.nix
  ];

  services = {
    knix = {
      enable = true;
      role = "agent";
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
