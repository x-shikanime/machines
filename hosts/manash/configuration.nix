{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/rke2-node.nix
  ];

  networking.hostName = "manash";

  hardware.facter.reportPath = ./facter.json;

  shikanime.rke2-node = {
    enable = true;
    mountLabel = "flandre";
    nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";
    podCidr = "10.244.0.0/24";
    ipv6PodCidr = "fd00::/112";
    isServer = true;
    sopsFile = ../../secrets/manash.enc.yaml;
  };

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];
}
