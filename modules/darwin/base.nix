{ config, ... }:

{
  imports = [
    ./minimal.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shikanime/shikanime.git";
      }
    ];
  };

  sops = {
    secrets.nix-access-token = { };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };
}
