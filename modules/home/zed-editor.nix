{ lib, pkgs, ... }:

with lib;

{
  programs.zed-editor = {
    enable = true;

    userSettings = {
      agent = {
        new_thread_location = "new_worktree";
        default_model = {
          provider = "Hermes Agent";
          model = "hermes-agent";
          enable_thinking = true;
        };
      };

      agent_servers = {
        "Hermes Agent" = {
          type = "custom";
          command = "hermes";
          args = [ "acp" ];
        };
      };

      icon_theme = mkForce {
        mode = "system";
        light = "Catppuccin Latte";
        dark = "Catppuccin Frappé";
      };

      language_models = {
        openai_compatible = {
          "Hermes Agent" = {
            api_url = "http://localhost:8642/v1";
            available_models = [
              {
                name = "hermes-agent";
                max_tokens = 200000;
                max_output_tokens = 32000;
                max_completion_tokens = 200000;
                capabilities = {
                  tools = true;
                  images = true;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                  chat_completions = true;
                };
              }
            ];
          };
        };
      };

      helix_mode = true;

      relative_line_numbers = "enabled";

      terminal.shell.program = "${getExe pkgs.zsh} -c ${getExe pkgs.nushell}";

      theme = {
        mode = "system";
        light = mkForce "Catppuccin Latte";
        dark = mkForce "Catppuccin Frappé";
      };

      vim_mode = true;
    };
  };
}
