{ lib, ... }:

with lib;

{
  programs.helix = {
    defaultEditor = true;
    enable = true;
    settings = {
      editor = {
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        cursorline = true;
        indent-guides.render = true;
        line-number = "relative";
      };
      theme = mkForce {
        dark = "catppuccin-frappe";
        light = "catppuccin-latte";
      };
    };
  };
}
