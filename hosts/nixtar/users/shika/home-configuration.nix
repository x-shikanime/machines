{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  toDhall = generators.toDhall { };
  ini = pkgs.formats.ini { };
  yaml = pkgs.formats.yaml { };
in
{
  imports = [
    ../../../../modules/home/base.nix
    ../../../../modules/home/cloud.nix
    ../../../../modules/home/fontconfig.nix
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

  home.sessionVariables.GHSTACKRC_PATH = config.lib.file.mkOutOfStoreSymlink config.sops.templates.ghstack-config.path;

  programs = {
    bash.enable = true;

    docker-cli.settings.credsStore = "pass";
  };

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/nixtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      cachix-token = { };
      github-token = { };
      gitlab-token = { };
    };
    templates = {
      cachix-config.content = toDhall {
        authToken = config.sops.placeholder.cachix-token;
        hostname = "https://cachix.org";
      };
      ghstack-config = {
        file = ini.generate "ghstackrc" {
          ghstack = {
            github_oauth = config.sops.placeholder.github-token;
            github_url = "github.com";
            github_username = "shikanime";
          };
        };
        mode = "0640";
      };
      glab-cli-config.file = yaml.generate "config.yaml" {
        git_protocol = "https";
        hosts.gitlab.com = {
          api_host = "gitlab.com";
          api_protocol = "https";
          token = config.sops.placeholder.gitlab-token;
        };
      };
    };
  };

  xdg.configFile = {
    "cachix/cachix.dhall".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates.cachix-config.path;
    "glab-cli/config.yml" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.glab-cli-config.path;
    };
  };
}
