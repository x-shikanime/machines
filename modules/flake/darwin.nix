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
        inputs.home-manager.darwinModules.home-manager
        inputs.sops-nix.darwinModules.sops
        {
          home-manager.sharedModules = [
            inputs.devlib.homeManagerModule
            inputs.colemak.homeManagerModule
            inputs.sops-nix.homeManagerModule
          ];
        }
      ];
    };
    packages.aarch64-darwin.telsha = self.darwinConfigurations.telsha.system;
  };
}
