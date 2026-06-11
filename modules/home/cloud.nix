{ pkgs, ... }:

{
  catppuccin.k9s.enable = false;

  programs = {
    k9s = {
      enable = true;
      settings.k9s.ui.skin = "transparent";
    };

    ssh.settings."ssh.dev.azure.com" = {
      HostkeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedKeyTypes = "+ssh-rsa";
    };
  };

  xdg.configFile."containers/policy.json".source =
    let
      format = pkgs.formats.json { };
    in
    format.generate "policy.json" {
      default = [
        { type = "insecureAcceptAnything"; }
      ];
      transports.docker-daemon = {
        "" = [ { type = "insecureAcceptAnything"; } ];
      };
    };
}
