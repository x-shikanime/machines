{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/rpi.nix
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

  networking.hostName = "minish";

  services.knix.nodeIP = "192.168.1.29";

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
