{ config, lib, ... }:

with lib;

let
  settings = importTOML "${config.catppuccin.sources.starship}/latte.toml";
in
{
  programs.starship = {
    enable = true;
    settings = {
      directory = {
        truncation_length = 4;
        style = "bold lavender";
      };
      git_branch.style = "bold mauve";
      palette = "catppuccin_latte";
    }
    // settings;
  };
}
