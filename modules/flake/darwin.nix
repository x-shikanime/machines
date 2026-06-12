{ self, ... }:
{ inputs, ... }:

{
  flake = {
    darwinConfigurations.telsha = inputs.nix-darwin.lib.darwinSystem {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/telsha/darwin-configuration.nix
        inputs.home-manager.darwinModules.default
        inputs.sops-nix.darwinModules.default
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
    packages.aarch64-darwin.telsha = self.darwinConfigurations.telsha.system;
  };
}
