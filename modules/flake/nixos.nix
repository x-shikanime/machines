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
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-wsl.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModule
              inputs.colemak.homeModule
              inputs.sops-nix.homeModule
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
                    inputs.devlib.homeModule
                    inputs.colemak.homeModule
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
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.sharedModules = [
                    inputs.devlib.homeModule
                    inputs.colemak.homeModule
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
