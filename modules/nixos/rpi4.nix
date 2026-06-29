{
  imports = [
    ./rpi.nix
  ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;
}
