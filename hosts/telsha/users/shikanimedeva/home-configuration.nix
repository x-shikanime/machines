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
    ../../../../modules/home/ghostty.nix
    ../../../../modules/home/helix.nix
    ../../../../modules/home/starship.nix
    ../../../../modules/home/vcs.nix
    ../../../../modules/home/workstation.nix
    ../../../../modules/home/zed-editor.nix
  ];

  # Identity configuration — consumed by identities.homeModules.default
  identities.shikanime = {
    enable = true;
    email = config.sops.placeholder.shikanime-studio-email;
    sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFC5VCX4U04t82TizoUmXxZ064cOqNtswe0zPDqWWRj";
    git.gpgFormat = "ssh";
    sapling.enable = false;
  };

  identities.gouv = {
    enable = true;
    email = config.sops.placeholder.gouv-email;
    gpgKey = config.sops.placeholder.gouv-signing-key;
    git = {
      gpgFormat = "gpg";
      gitpath = "${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native";
    };
  };

  identities.operator-6o = {
    enable = true;
    email = config.sops.placeholder.operator6o-email;
    gpgKey = config.sops.placeholder.operator6o-signing-key;
    git = {
      gpgFormat = "gpg";
      gitpath = "${config.home.homeDirectory}/Source/Repos/github.com/operator6o";
    };
  };

  # Wire generated git includes into programs.git
  programs.git.includes = config.identities.git.includes;

  home = {
    file."Library/Preferences/sapling/sapling.conf".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates.sapling-config.path;
    sessionVariables = {
      GHSTACKRC_PATH = config.lib.file.mkOutOfStoreSymlink config.sops.templates.ghstack-config.path;
      SSH_AUTH_SOCK="${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh";
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

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

    git.signing.signByDefault = true;

    zsh.enable = true;
  };

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/telsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      cachix-token = { };
      github-token = { };
      gitlab-token = { };
      gouv-email = { };
      gouv-signing-key = { };
      operator6o-email = { };
      operator6o-signing-key = { };
      shikanime-studio-email = { };
      nix-access-token = { };
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
      nix-config.content = ''
        extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"'';
      sapling-config.file = ini.generate "sapling.conf" {
        alias = {
          ci = "ci --message-field Signed-off-by=\"William Phetsinorath <${config.sops.placeholder.shikanime-studio-email}>\"";
          commit = "commit --message-field Signed-off-by=\"William Phetsinorath <${config.sops.placeholder.shikanime-studio-email}>\"";
          push = "push --force";
        };
        committemplate = {
          commit-message-fields = "Summary,Fixes,Signed-off-by";
          emptymsg = "{if(title, title, defaulttitle)}\\n\\nSummary: {summary}\\n\\nFixes: {fixes}\\n\\nSigned-off-by: {author}";
        };
        diff-tools = {
          "zed.args" = "--wait --diff $local $other";
          "zed.gui" = true;
          "zed.priority" = 20;
        };
        gpg.key = "09CA52A835C14157";
        hooks = {
          "precommit.git-hooks" = "test -f .git/hooks/pre-commit && .git/hooks/pre-commit || true";
          "preoutgoing.git-hooks" = "test -f .git/hooks/pre-push && .git/hooks/pre-push || true";
          "update.git-hooks" = "test -f .git/hooks/post-rewrite && .git/hooks/post-rewrite || true";
        };
        merge-tools = {
          "mergiraf.args" = "merge --git $base $local $other -o $output";
          "mergiraf.priority" = 30;
        };
        ui = {
          editor = "hx";
          username = "William Phetsinorath <${config.sops.placeholder.shikanime-studio-email}>";
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
