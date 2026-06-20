{ config, ... }:

{
  # Make home-manager use packages from system
  home-manager = {
    backupFileExtension = "backup-before-nix";
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
      interval = [ { Weekday = 7; } ];
    };

    optimise = {
      automatic = true;
      interval = [ { Weekday = 7; } ];
    };

    settings = {
      download-buffer-size = 524288000;
      trusted-users = [ "@admin" ];
    };

    extraOptions = ''
      !include ${config.sops.templates.nix-config.path}
    '';
  };

  sops = {
    secrets.nix-access-token = { };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  # This value determines the Darwin release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system
  system.stateVersion = 6;
}
