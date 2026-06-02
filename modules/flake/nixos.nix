{ self, ... }:
{ inputs, ... }:

{
  flake = {
    nixosConfigurations = {
      manash = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/manash/configuration.nix
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      nixtar = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nixtar/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-wsl.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          {
            home-manager.sharedModules = [
              inputs.catppuccin.homeModules.default
              inputs.devlib.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
    };

    packages = {
      x86_64-linux = {
        catbox =
          let
            catbox = inputs.nixpkgs.lib.nixosSystem {
              pkgs = import inputs.nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              modules = [
                ../../hosts/catbox/configuration.nix
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.devlib.homeModules.default
                  ];
                }
              ];
            };
          in
          catbox.config.system.build.buildLayeredImage;
        manash = self.nixosConfigurations.manash.config.system.build.toplevel;
        nixtar = self.nixosConfigurations.nixtar.config.system.build.tarballBuilder;
      };
      aarch64-linux = {
        catbox =
          let
            catbox = inputs.nixpkgs.lib.nixosSystem {
              pkgs = import inputs.nixpkgs {
                system = "aarch64-linux";
                config.allowUnfree = true;
              };
              modules = [
                ../../hosts/catbox/configuration.nix
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.devlib.homeModules.default
                  ];
                }
              ];
            };
          in
          catbox.config.system.build.buildLayeredImage;
      };
    };
  };
}
