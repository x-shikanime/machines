{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  catppuccin = {
    enable = true;
    flavor = "latte";
  };

  colemak.enable = true;

  home = {
    packages = with pkgs; [
      bws
      cachix
      claude-code
      codex
      devenv
      docker-credential-helpers
      gemini-cli
      pass
      qpdf
      qwen-code
      rclone
      rtk
      secretspec
      wget
      zip
    ];
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  };

  # FIX: https://github.com/Mic92/sops-nix/issues/890
  launchd.agents.sops-nix = mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config.EnvironmentVariables.PATH = mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
  };

  programs = {
    bat.enable = true;

    carapace.enable = true;

    dircolors.enable = true;

    direnv = {
      enable = true;
      mise.enable = true;
      nix-direnv.enable = true;
      config.global.load_dotenv = true;
    };

    docker-cli.enable = true;

    gpg.enable = true;

    mergiraf = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };

    jujutsu.settings."merge-tools".mergiraf."merge-tool-edits-conflict-markers" = true;

    mise.enable = true;

    nix-index.enable = true;

    nushell = {
      enable = true;
      extraConfig = ''
        $env.config.show_banner = false

        source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/vscode/vscode-completions.nu
      '';
    };

    ripgrep.enable = true;

    ssh = {
      enable = true;
      settings = {
        "ashira.taila659a.ts.net" = {
          User = "nishir";
          SetEnv.TERM = "xterm-256color";
        };
        "catbox.taila659a.ts.net" = {
          User = "shika";
          SetEnv.TERM = "xterm-256color";
        };
        "fushi.taila659a.ts.net" = {
          User = "talashi";
          SetEnv.TERM = "xterm-256color";
        };
        "manash.taila659a.ts.net" = {
          User = "nishir";
          SetEnv.TERM = "xterm-256color";
        };
        "minish.taila659a.ts.net" = {
          User = "talashi";
          SetEnv.TERM = "xterm-256color";
        };
        "nalsha.taila659a.ts.net" = {
          User = "nishir";
          SetEnv.TERM = "xterm-256color";
        };
        "nemishi.taila659a.ts.net" = {
          User = "talashi";
          SetEnv.TERM = "xterm-256color";
        };
        "thinkcentre-m710t.tailfb4bb2.ts.net" = {
          ForwardX11 = true;
          User = "william-phetsinorath";
          SetEnv.TERM = "xterm-256color";
        };
      };
    };

    zoxide.enable = true;
  };

  xdg.enable = true;
}
