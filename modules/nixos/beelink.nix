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

  # Allow pod CIDR traffic on physical NICs (cross-node pod↔host).
  # Hardware-specific: Beelink uses Intel i226-V 2.5 Gbps on enp1s0/enp2s0.
  networking.firewall.extraCommands = ''
    for __beelink_fw_iface in enp1s0 enp2s0; do
      ip link show "$__beelink_fw_iface" >/dev/null 2>&1 || continue
      iptables -I INPUT -i "$__beelink_fw_iface" -s 10.244.0.0/16 -j ACCEPT
      iptables -I INPUT -i "$__beelink_fw_iface" -s 10.42.0.0/16 -j ACCEPT
      iptables -I FORWARD -i "$__beelink_fw_iface" -s 10.244.0.0/16 -j ACCEPT
      iptables -I FORWARD -i "$__beelink_fw_iface" -d 10.244.0.0/16 -j ACCEPT
      ip6tables -I INPUT -i "$__beelink_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -I FORWARD -i "$__beelink_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -I FORWARD -i "$__beelink_fw_iface" -d fd00::/10 -j ACCEPT 2>/dev/null || true
    done
  '';
  networking.firewall.extraStopCommands = ''
    for __beelink_fw_iface in enp1s0 enp2s0; do
      iptables -D INPUT -i "$__beelink_fw_iface" -s 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D INPUT -i "$__beelink_fw_iface" -s 10.42.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i "$__beelink_fw_iface" -s 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i "$__beelink_fw_iface" -d 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      ip6tables -D INPUT -i "$__beelink_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i "$__beelink_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i "$__beelink_fw_iface" -d fd00::/10 -j ACCEPT 2>/dev/null || true
    done
  '';

  # Consolidated network performance tuning for Beelink (Intel N150, 2.5 Gbps NIC)
  # Previously was only tailscale-udp-gro-forwarding; expanded to enable full
  # hardware offloads (TSO/GSO/checksum) and RPS packet steering across cores.
  systemd.services.network-nic-performance = {
    after = [ "network-online.target" ];
    description = "Enable NIC hardware offloads and RPS for enp1s0";
    script = ''
      for __beelink_iface in enp1s0 enp2s0; do
        ip link show "$__beelink_iface" >/dev/null 2>&1 || continue
        # Tailscale UDP GRO forwarding (original behavior preserved)
        ${pkgs.ethtool}/bin/ethtool -K "$__beelink_iface" rx-udp-gro-forwarding on rx-gro-list off
        # Hardware offloads: reduce CPU per-byte overhead
        ${pkgs.ethtool}/bin/ethtool -K "$__beelink_iface" tso on gso on sg on tx on rx on 2>/dev/null || true
        # Receive Packet Steering: distribute IRQs across all CPU cores
        for __beelink_rxq in /sys/class/net/"$__beelink_iface"/queues/rx-*; do
          echo f > "$__beelink_rxq"/rps_cpus 2>/dev/null || true
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
