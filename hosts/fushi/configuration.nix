{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
    ../../modules/nixos/rpi.nix
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

  networking.hostName = "fushi";

  services.knix.nodeIP = "192.168.1.30";

  sops = {
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
