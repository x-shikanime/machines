{ lib, ... }:

{
  knix = {
    flux = {
      enable = lib.mkDefault true;
      instance.extraConfig.instance.sync = lib.mkDefault {
        interval = "1m";
        kind = "GitRepository";
        path = "clusters/nishir/overlays/tailnet";
        pullSecret = "";
        ref = "refs/heads/main";
        url = "https://github.com/shikanime/manifests.git";
      };
    };
  };
}
