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
            inputs.devlib.homeModule
            inputs.colemak.homeModule
            inputs.sops-nix.homeModule
          ];
        }
      ];
    };
    packages.aarch64-darwin.telsha = self.darwinConfigurations.telsha.system;
  };
}
