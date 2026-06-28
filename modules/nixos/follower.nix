{ config, ... }:

{
  imports = [
    ./server.nix
  ];

  services.knix = {
    serverAddr = "https://nishir.taila659a.ts.net:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops.secrets.rke2-token.restartUnits = [ "rke2-server.service" ];
}
