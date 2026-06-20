{
  config,
  lib,
  ...
}:

with lib;

let
  toDhall = generators.toDhall { };
in
{
  imports = [
    ../../../../modules/home/base.nix
    ../../../../modules/home/cloud.nix
    ../../../../modules/home/fontconfig.nix
    ../../../../modules/home/ghostty.nix
    ../../../../modules/home/helix.nix
    ../../../../modules/home/starship.nix
    ../../../../modules/home/vcs.nix
    ../../../../modules/home/workstation.nix
    ../../../../modules/home/zed-editor.nix
  ];

  identities = {
    shikanime.enable = true;

    gouv = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native";
      jj.extraConfig."--when.repositories" = [
        "${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native"
      ];
    };

    operator-6o = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/operator6o";
      jj.extraConfig."--when.repositories" = [
        "${config.home.homeDirectory}/Source/Repos/github.com/operator6o"
      ];
    };
  };

  home = {
    sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
    };
  };

  programs = {
    bash.enable = true;

    docker-cli = {
      contexts.rancher-desktop = {
        Endpoints = {
          docker = {
            Host = "unix://${config.home.homeDirectory}/.rd/docker.sock";
            SkipTLSVerify = false;
          };
        };
        Metadata.Description = "Rancher Desktop moby context";
      };
      settings = {
        credsStore = "osxkeychain";
        currentContext = "rancher-desktop";
      };
    };

    zsh.enable = true;
  };

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/telsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.cachix-token = { };
    templates = {
      cachix-config.content = toDhall {
        authToken = config.sops.placeholder.cachix-token;
        hostname = "https://cachix.org";
      };
    };
  };

  xdg.configFile."cachix/cachix.dhall".source =
    config.lib.file.mkOutOfStoreSymlink config.sops.templates.cachix-config.path;
}
