{
  imports = [
    ./follower.nix
    ./node.nix
  ];

  services.knix = {
    enable = true;
    role = "agent";
  };

  sops.secrets.rke2-token.restartUnits = [ "rke2-agent.service" ];
}
