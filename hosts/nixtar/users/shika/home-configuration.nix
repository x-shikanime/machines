{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  toDhall = generators.toDhall { };

  gitIni = pkgs.formats.gitIni { };
  ini = pkgs.formats.ini { };
  toml = pkgs.formats.toml { };
  yaml = pkgs.formats.yaml { };

  name = "William Phetsinorath";
  gpgSigningKey = "721388256B3D78FA";
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

  home.sessionVariables.GHSTACKRC_PATH = config.lib.file.mkOutOfStoreSymlink config.sops.templates.ghstack-config.path;

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  programs = {
    bash.enable = true;

    docker-cli.settings.credsStore = "pass";

    git = {
      includes = [
        { path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.git-config.path; }
      ];
      signing = {
        format = "ssh";
        signByDefault = true;
      };
    };
  };

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/nixtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      cachix-token = { };
      github-token = { };
      gitlab-token = { };
      gouv-email = { };
      gouv-signing-key = { };
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
      git-config.file = gitIni.generate "config" {
        gpg.format = "ssh";
        user = {
          inherit name;
          signingkey =
            let
              signingkey = pkgs.writeText "id_ed25519.pub" ''
                ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFC5VCX4U04t82TizoUmXxZ064cOqNtswe0zPDqWWRj
              '';
            in
            "${signingkey}";
          email = config.sops.placeholder.shikanime-studio-email;
        };
      };
      jujutsu-config.file = toml.generate "config.toml" {
        signing = {
          backend = "ssh";
          behavior = "own";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFC5VCX4U04t82TizoUmXxZ064cOqNtswe0zPDqWWRj";
        };
        user = {
          inherit name;
          email = config.sops.placeholder.shikanime-studio-email;
        };
      };
      juju-gouv-config.file = toml.generate "config.toml" {
        "--when.repositories" = [ "~/Source/Repos/github.com/cloud-pi-native" ];
        signing.key = config.sops.placeholder.gouv-signing-key;
        user = {
          email = config.sops.placeholder.gouv-email;
          inherit name;
        };
      };
      nix-config.content = ''
        extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
      '';
      sapling-config.file = ini.generate "sapling.conf" {
        alias = {
          ci = "ci --message-field Signed-off-by=\"${name} <${config.sops.placeholder.shikanime-studio-email}>\"";
          commit = "commit --message-field Signed-off-by=\"${name} <${config.sops.placeholder.shikanime-studio-email}>\"";
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
        gpg.key = gpgSigningKey;
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
          username = "${name} <${config.sops.placeholder.shikanime-studio-email}>";
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
    "jj/conf.d/default.toml".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates.jujutsu-config.path;
    "juju/conf.d/gouv.conf".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates.juju-gouv-config.path;
    "sapling/sapling.conf".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates.sapling-config.path;
  };
}
