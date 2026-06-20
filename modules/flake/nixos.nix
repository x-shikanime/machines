{ self, ... }:
{ inputs, ... }:

{
  flake = {
    nixosConfigurations = {
      ashira = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/ashira/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      manash = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/manash/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      nalsha = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nalsha/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      fushi = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/fushi/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      minish = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/minish/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
      nemishi = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nemishi/configuration.nix
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.knix.nixosModules.default
          inputs.nixos-hardware.nixosModules.raspberry-pi-5
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
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
          inputs.home-manager.nixosModules.default
          inputs.nixos-wsl.nixosModules.default
          inputs.sops-nix.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.catppuccin.homeModules.default
              inputs.colemak.homeModules.default
              inputs.devlib.homeModules.default
              inputs.identities.homeModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
      };
    };

    packages = {
      x86_64-linux = {
        ashira = self.nixosConfigurations.ashira.config.system.build.toplevel;
        catbox =
          let
            catbox = inputs.nixpkgs.lib.nixosSystem {
              pkgs = import inputs.nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              modules = [
                ../../hosts/catbox/configuration.nix
                inputs.home-manager.nixosModules.default
                inputs.sops-nix.nixosModules.default
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.colemak.homeModules.default
                    inputs.devlib.homeModules.default
                    inputs.identities.homeModules.default
                    inputs.sops-nix.homeModules.default
                  ];
                }
              ];
            };
          in
          catbox.config.system.build.buildLayeredImage;
        manash = self.nixosConfigurations.manash.config.system.build.toplevel;
        nalsha = self.nixosConfigurations.nalsha.config.system.build.toplevel;
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
                inputs.home-manager.nixosModules.default
                inputs.sops-nix.nixosModules.default
                {
                  home-manager.sharedModules = [
                    inputs.catppuccin.homeModules.default
                    inputs.colemak.homeModules.default
                    inputs.devlib.homeModules.default
                    inputs.identities.homeModules.default
                    inputs.sops-nix.homeModules.default
                  ];
                }
              ];
            };
          in
          catbox.config.system.build.buildLayeredImage;
        fushi = self.nixosConfigurations.fushi.config.system.build.toplevel;
        minish = self.nixosConfigurations.minish.config.system.build.toplevel;
        nemishi = self.nixosConfigurations.nemishi.config.system.build.toplevel;
      };
    };
  };
}
