{ config, ... }:

{
  imports = [
    ../../modules/nixos/telashi.nix
    ../../modules/nixos/distributed.nix
  ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-label/reimu";
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

  networking.hostName = "fushi";

  knix = {
    nodeIP = "192.168.1.30";
    serverAddr = "https://nishir.taila659a.ts.net:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };

  sops = {
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
