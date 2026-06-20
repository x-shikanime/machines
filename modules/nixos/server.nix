{ pkgs, ... }:

{
  imports = [
    ./node.nix
  ];

  services = {
    gitea-actions-runner.package = pkgs.forgejo-runner;

    nix-serve.enable = true;
  };

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    useDefaultShell = true;
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
