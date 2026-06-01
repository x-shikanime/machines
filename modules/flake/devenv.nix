{ inputs, ... }:

{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    {
      devenv.shells.default = {
        imports = [
          inputs.devlib.devenvModules.git
          inputs.devlib.devenvModules.nix
          inputs.devlib.devenvModules.opentofu
          inputs.devlib.devenvModules.shell
          inputs.devlib.devenvModules.shikanime
        ];

        github = {
          settings.workflows = {
            integration = {
              jobs.skaffold = {
                needs = [ "nix" ];
                secrets.CACHIX_AUTH_TOKEN = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              };
              on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;
            };

            release = {
              jobs.skaffold = {
                needs = [ "nix" ];
                secrets.CACHIX_AUTH_TOKEN = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              };
              on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;
            };

            skaffold.on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;

            wakabox = {
              name = "Wakabox";
              on.schedule = [
                { cron = "0 0 * * *"; }
              ];
              jobs.wakabox = {
                runs-on = "ubuntu-latest";
                steps = [
                  {
                    uses = "matchai/waka-box@v5.0.0";
                    env = {
                      GH_TOKEN = "\${{ secrets.WAKABOX_GITHUB_TOKEN }}";
                      GIST_ID = "\${{ vars.WAKABOX_GITHUB_GIST_ID }}";
                      WAKATIME_API_KEY = "\${{ secrets.WAKATIME_API_KEY }}";
                    };
                  }
                ];
              };
              permissions.contents = "read";
            };
          };

          workflows.skaffold = {
            enable = true;
            settings.setup-nix = {
              cachix-auth-token = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              extra-platforms = "arm64";
            };
          };
        };

        packages =
          with pkgs;
          [
            age
            skaffold
          ]
          ++ lib.optional stdenv.hostPlatform.isLinux nixos-facter;

        sops = {
          enable = true;
          settings.creation_rules =
            let
              age = [
                "age1pwl9yz4k4255a4h8qz7lafce8wxhsul0cnqwmr8528fqgujlfshshv3z3g" # telsha
                "age1x9v4ps90txy9mk4392uya93tyzx40te4dvns4chg5s6q8mfy03ns74jpay" # nixtar
              ];
            in
            [
              {
                path_regex = "secrets/minish.enc.yaml";
                key_groups = [
                  {
                    age = age ++ [
                      "age1f4yuh4j3gqafjduusfpxz3na9xtwth9s6gznq043mfex0zglp5jqkkdm64" # host
                    ];
                  }
                ];
              }
              {
                path_regex = "secrets/nixtar.enc.yaml";
                key_groups = [
                  {
                    age = age ++ [
                      "age1um232l0h8wn9mtha2qf4f4mnf7ucjayvf5qxjvynatmasg8qg5mshekvjl" # host
                    ];
                  }
                ];
              }
              {
                path_regex = "secrets/telsha.enc.yaml";
                key_groups = [
                  {
                    age = age ++ [
                      "age1eak84xcr44yfqsg843rfu2xajxsyvjwh67a630htpnd0scy7yu5szjfh8d" # host
                    ];
                  }
                ];
              }
            ];
        };

        treefmt.config.programs.typos.configFile =
          let
            format = pkgs.formats.toml { };
            settings = {
              default.extend-words.facter = "facter";
            };
            configFile = format.generate "typos.toml" settings;
          in
          "${configFile}";
      };
    };
}
