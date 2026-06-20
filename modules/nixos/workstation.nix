{ pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-all;
    settings.default-cache-ttl = 60 * 60;
  };
}
