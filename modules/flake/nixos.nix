{ self, ... }:
{ inputs, ... }:

{
  flake = {
    nixosConfigurations = {
      nixtar = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nixtar/configuration.nix
          inputs.catppuccin.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.nixos-wsl.nixosModules.default
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.catppuccin.homeModules.default
              inputs.colemak.homeModules.default
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
                inputs.catppuccin.nixosModules.default
                inputs.home-manager.nixosModules.default
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.colemak.homeModules.default
                    inputs.devlib.homeModules.default
                  ];
                }
              ];
            };
          in
          catbox.config.system.build.buildLayeredImage;
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
                inputs.catppuccin.nixosModules.default
                inputs.home-manager.nixosModules.default
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.colemak.homeModules.default
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
