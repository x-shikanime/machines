{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/rke2-node.nix
  ];

  networking.hostName = "ashira";

  hardware.facter.reportPath = ./facter.json;

  shikanime.rke2-node = {
    enable = true;
    mountLabel = "patchouli";
    nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";
    podCidr = "10.244.2.0/24";
    ipv6PodCidr = "fd00::2:0/112";
    serverAddr = "https://192.168.1.28:9345";
    sopsFile = ../../secrets/ashira.enc.yaml;
  };

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];
}
