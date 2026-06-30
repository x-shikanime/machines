{ pkgs, ... }:

{
  # Older Raspberry Pi-class boards still need these cgroup knobs for RKE2.
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Allow pod CIDR traffic on physical NICs (cross-node pod↔host).
  # Hardware-specific: Raspberry Pi uses USB3 GigE on end0 (CM4) or eth0.
  networking.firewall.extraCommands = ''
    for __rpi_fw_iface in end0; do
      ip link show "$__rpi_fw_iface" >/dev/null 2>&1 || continue
      iptables -I INPUT -i "$__rpi_fw_iface" -s 10.244.0.0/16 -j ACCEPT
      iptables -I INPUT -i "$__rpi_fw_iface" -s 10.42.0.0/16 -j ACCEPT
      iptables -I FORWARD -i "$__rpi_fw_iface" -s 10.244.0.0/16 -j ACCEPT
      iptables -I FORWARD -i "$__rpi_fw_iface" -d 10.244.0.0/16 -j ACCEPT
      ip6tables -I INPUT -i "$__rpi_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -I FORWARD -i "$__rpi_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -I FORWARD -i "$__rpi_fw_iface" -d fd00::/10 -j ACCEPT 2>/dev/null || true
    done
  '';
  networking.firewall.extraStopCommands = ''
    for __rpi_fw_iface in end0; do
      iptables -D INPUT -i "$__rpi_fw_iface" -s 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D INPUT -i "$__rpi_fw_iface" -s 10.42.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i "$__rpi_fw_iface" -s 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i "$__rpi_fw_iface" -d 10.244.0.0/16 -j ACCEPT 2>/dev/null || true
      ip6tables -D INPUT -i "$__rpi_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i "$__rpi_fw_iface" -s fd00::/10 -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i "$__rpi_fw_iface" -d fd00::/10 -j ACCEPT 2>/dev/null || true
    done
  '';

  # Consolidated network performance tuning for Raspberry Pi (1 Gbps NIC)
  # Previously only tailscale UDP GRO; expanded to enable offloads + RPS.
  systemd.services.nic-performance = {
    after = [ "network-online.target" ];
    description = "Enable NIC hardware offloads and RPS for Pi";
    script = ''
      for __rpi_iface in end0; do
        ip link show "$__rpi_iface" >/dev/null 2>&1 || continue
        # Tailscale UDP GRO forwarding (original behavior preserved)
        ${pkgs.ethtool}/bin/ethtool -K "$__rpi_iface" rx-udp-gro-forwarding on rx-gro-list off
        # Hardware offloads (best-effort: some may not be supported by Pi NIC)
        ${pkgs.ethtool}/bin/ethtool -K "$__rpi_iface" tso on gso on sg on tx on rx on 2>/dev/null || true
        # RPS: distribute IRQs across cores (Pi4 has 4 cores)
        for __rpi_rxq in /sys/class/net/"$__rpi_iface"/queues/rx-*; do
          echo f > "$__rpi_rxq"/rps_cpus 2>/dev/null || true
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
