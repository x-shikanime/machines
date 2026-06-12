{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/rke2-node.nix
  ];

  networking.hostName = "nalsha";

  hardware.facter.reportPath = ./facter.json;

  shikanime.rke2-node = {
    enable = true;
    mountLabel = "remilia";
    nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";
    podCidr = "10.244.1.0/24";
    ipv6PodCidr = "fd00::1:0/112";
    serverAddr = "https://192.168.1.28:9345";
    sopsFile = ../../secrets/nalsha.enc.yaml;
  };

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];
}
