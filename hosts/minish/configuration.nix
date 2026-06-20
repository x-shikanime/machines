{ config, ... }:

{
  imports = [
    ../../modules/nixos/telashi.nix
    ../../modules/nixos/distributed.nix
  ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-label/marisa";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
          };
        };
      };
    };
  };

  home-manager.users.telashi.imports = [
    ./users/telashi/home-configuration.nix
  ];

  networking.hostName = "minish";

  knix = {
    nodeIP = "192.168.1.29";
    serverAddr = "https://nishir.taila659a.ts.net:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
