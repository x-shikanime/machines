{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/distributed.nix
    ../../modules/darwin/workstation.nix
  ];

  home-manager.users.shikanimedeva.imports = [
    ./users/shikanimedeva/home-configuration.nix
  ];

  networking.hostName = "telsha";

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/telsha.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  # GitOps deployment via comin
  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/shikanime/shikanime.git";
    }];
  };

  system.primaryUser = "shikanimedeva";

  users.users.shikanimedeva = {
    home = "/Users/shikanimedeva";
    name = "shikanimedeva";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
