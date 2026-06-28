{ inputs, ... }:

{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    let
      toml = pkgs.formats.toml { };
    in
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
              telsha = "age1pwl9yz4k4255a4h8qz7lafce8wxhsul0cnqwmr8528fqgujlfshshv3z3g";
              nixtar = "age1x9v4ps90txy9mk4392uya93tyzx40te4dvns4chg5s6q8mfy03ns74jpay";
              ashira = "age1mel902ydxqv4yh798t5en336am9zwykapy8rtfvq4yprzr79t5wqzxe8ph";
              fushi = "";
              manash = "age1f4yuh4j3gqafjduusfpxz3na9xtwth9s6gznq043mfex0zglp5jqkkdm64";
              minish = "";
              nalsha = "age1evzl6xw2n96l2xyy7jed3zlv6d4jpmytp47rpp39pjju08tep4mqqa2au5";
              nemishi = "";

              workstations = [
                telsha
                nixtar
              ];

              nodes = [
                ashira
                fushi
                manash
                minish
                nalsha
                nemishi
              ];
            in
            [
              {
                path_regex = "secrets/ashira.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ ashira ]; }
                ];
              }
              {
                path_regex = "secrets/fushi.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ fushi ]; }
                ];
              }
              {
                path_regex = "secrets/manash.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ manash ]; }
                ];
              }
              {
                path_regex = "secrets/minish.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ minish ]; }
                ];
              }
              {
                path_regex = "secrets/nalsha.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ nalsha ]; }
                ];
              }
              {
                path_regex = "secrets/nemishi.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes ++ [ nemishi ]; }
                ];
              }
              {
                path_regex = "secrets/nishir.enc.yaml";
                key_groups = [
                  { age = workstations ++ nodes; }
                ];
              }
              {
                path_regex = "secrets/nixtar.enc.yaml";
                key_groups = [
                  { age = workstations; }
                ];
              }
              {
                path_regex = "secrets/telsha.enc.yaml";
                key_groups = [
                  { age = workstations; }
                ];
              }
            ];
        };

        treefmt.config.programs.typos.configFile =
          let
            configFile = toml.generate "typos.toml" {
              default.extend-words.facter = "facter";
            };
          in
          toString configFile;
      };
    };
}
