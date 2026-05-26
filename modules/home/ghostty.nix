{ lib, pkgs, ... }:

with lib;

{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.ghostty-bin;
    settings = {
      theme = "dark:catppuccin-frappe,light:catppuccin-latte";
      command = "${getExe pkgs.zsh} -c ${getExe pkgs.nushell}";
    };
  };
}
