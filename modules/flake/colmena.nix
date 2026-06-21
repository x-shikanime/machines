{ self, ... }:
{ inputs, ... }:

{
  flake.colmena = {
    defaults = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        {
          home-manager.sharedModules = [
            inputs.devlib.homeModules.default
            inputs.identities.homeModules.default
            inputs.sops-nix.homeModules.default
          ];
        }
      ];
      deployment = {
        targetUser = "root";
        targetHost = null;
        buildOnTarget = false;
      };
    };

    ashira = {
      imports = [
        ../../hosts/ashira/configuration.nix
      ];
      deployment.targetHost = "ashira.taila659a.ts.net";
    };

    manash = {
      imports = [
        ../../hosts/manash/configuration.nix
      ];
      deployment.targetHost = "manash.taila659a.ts.net";
    };

    nalsha = {
      imports = [
        ../../hosts/nalsha/configuration.nix
      ];
      deployment.targetHost = "nalsha.taila659a.ts.net";
    };

    fushi = {
      imports = [
        ../../hosts/fushi/configuration.nix
      ];
      deployment.targetHost = "fushi.taila659a.ts.net";
    };

    minish = {
      imports = [
        ../../hosts/minish/configuration.nix
      ];
      deployment.targetHost = "minish.taila659a.ts.net";
    };

    nemishi = {
      imports = [
        ../../hosts/nemishi/configuration.nix
      ];
      deployment.targetHost = "nemishi.taila659a.ts.net";
    };
  };
}
