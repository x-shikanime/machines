{ config, ... }:

{
  imports = [
    ./node.nix
  ];

  services.knix = {
    enable = false;
    role = "agent";
    serverAddr = "https://192.168.1.28:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops.secrets.rke2-token.restartUnits = [ "rke2-agent.service" ];
}
