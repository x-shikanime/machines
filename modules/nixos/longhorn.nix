{ pkgs, ... }:

{
  # Enable iscsi protocol support at kernel level
  boot.kernelModules = [
    "dm_crypt"
    "iscsi_tcp"
  ];

  # Enable NFS support at kernel level
  boot.supportedFilesystems = [ "nfs" ];

  environment.systemPackages = [
    pkgs.cryptsetup
    pkgs.lvm2
    pkgs.nfs-utils
    pkgs.openiscsi
  ];

  # FIXME: https://github.com/longhorn/longhorn/issues/2166
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
}
