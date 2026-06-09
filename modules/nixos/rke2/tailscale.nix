{
  config,
  lib,
  ...
}:

let
  cfg = config.shikanime.rke2;
in
with lib;
{
  options.shikanime.rke2.tailscale = mkOption {
    type = types.submodule {
      options.enable = mkEnableOption "RKE2 Tailscale integration";
    };
    default = { };
    description = "Tailscale integration for the Shikanime RKE2 stack.";
  };

  config = mkIf (cfg.enable && cfg.tailscale.enable) {
    services.tailscale.extraUpFlags = [
      "--accept-routes"
    ]
    ++ optional (cfg.clusterCidrs != null) "--advertise-routes=${cfg.clusterCidrs}";

    networking.firewall.interfaces.tailscale0.allowedUDPPorts = [
      8472
    ];
  };
}
