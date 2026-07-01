{ pkgs, ... }:

{
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
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

  # Intel N150 needs firmware plus userspace graphics/QSV libraries so the
  # Jellyfin pod can use VAAPI/QSV via /dev/dri/renderD128.
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.fstrim.enable = true;

  networking = {
    useNetworkd = true;

    # active-backup (mode 1): one NIC active, the other passive.
    # The MS308 is unmanaged, so this avoids multipath/ALB negotiation edge cases
    # while still giving automatic failover if one link or NIC dies.
    bonds.bond0 = {
      interfaces = [
        "enp1s0"
        "enp2s0"
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
      };
    };

    bridges.br0.interfaces = [ "bond0" ];
  };

  # NIC performance tuning: hardware offloads + RPS for both Intel i226-V ports.
  systemd.services.network-nic-performance = {
    after = [ "network-online.target" ];
    description = "Enable NIC hardware offloads and RPS";
    script = ''
      for iface in enp1s0 enp2s0; do
        ip link show "$iface" >/dev/null 2>&1 || continue
        ${pkgs.ethtool}/bin/ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off
        ${pkgs.ethtool}/bin/ethtool -K "$iface" tso on gso on sg on tx on rx on 2>/dev/null || true
        for rxq in /sys/class/net/"$iface"/queues/rx-*; do
          echo f > "$rxq"/rps_cpus 2>/dev/null || true
        done
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
  };
}
