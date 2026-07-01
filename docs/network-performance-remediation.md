# Network Performance Remediation — Switch Flannel to host-gw

## Problem

Cross-node pod-to-pod throughput is ~535 Mbps on Beelink nodes (2.5 Gbps NICs)
and ~400 Mbps estimated on Raspberry Pi 4 nodes (1 Gbps NICs). This is far below
the theoretical capacity (80% target = 2,000 Mbps for Beelink, 800 Mbps for
Pi4).

## Root Cause

The `rke2-canal` ConfigMap configures flannel with `Backend: wireguard`, which
encrypts all cross-node traffic with kernel WireGuard (ChaCha20-Poly1305).
WireGuard single-flow encryption is CPU-limited:

| Hardware             | Single-core WireGuard |
| -------------------- | --------------------- |
| Intel N150 (Beelink) | ~800-1,200 Mbps       |
| BCM2711 (Pi4, NEON)  | ~400-600 Mbps         |

Since all cluster nodes are on the **same Layer 2 subnet** (192.168.1.0/24),
WireGuard encryption is pure overhead — it adds CPU load without providing
security (the traffic never leaves the physical LAN).

## Remedy

Switch flannel backend from `wireguard` to `host-gw`. host-gw installs static
routes via the Linux routing table — zero encapsulation, zero encryption
overhead.

### Procedure

This change requires a **rolling restart of RKE2 on each node** because the CNI
configuration is read at node startup.

### Step 1: Switch flannel backend via knix canal options

The `services.knix.canal` options are provided by the `canal.nix` module in
[shikanime-studio/knix](https://github.com/shikanime-studio/knix). The backend
is set to `host-gw` globally for all cluster nodes:

```nix
# modules/nixos/node.nix
services.knix.canal.backend = "host-gw";
```

Per-host override (if needed):

```nix
services.knix.canal.backend = lib.mkForce "vxlan";
```

Defaults (when importing knix):

- `backend = "wireguard"` (backward compatible)
- `vethMtu = "1500"` for host-gw, `"1400"` for wireguard
- `wireguardKeepAlive = 25` (only when backend = wireguard)

### Step 2: Restart canal to apply

```bash
kubectl rollout restart ds -n kube-system rke2-canal
```

## Expected Results After All Remediations Combined

| Path                | Current (wireguard) | After host-gw | After +offloads | Target (80%) |
| ------------------- | ------------------- | ------------- | --------------- | ------------ |
| Beelink <-> Beelink | ~535 Mbps           | ~2,200 Mbps   | ~2,400 Mbps     | 2,000 Mbps   |
| Pi4 <-> Pi4         | ~400 Mbps           | ~900 Mbps     | ~940 Mbps       | 800 Mbps     |
| Beelink <-> Pi4     | ~450 Mbps           | ~1,500 Mbps   | ~1,800 Mbps     | —            |

## Related Changes (in this PR)

1. `shikanime-studio/knix` — New `modules/canal.nix` module upstreamed.
   `services.knix.canal.backend` option (host-gw | vxlan | wireguard) with
   per-host override. Default: wireguard (backward compatible). Also sets
   `vethMtu` automatically per backend and loads WireGuard kernel module when
   needed. `rke2.nix` updated to use `cfg.canal` values in the HelmChartConfig
   manifest.

2. `modules/nixos/node.nix` — Firewall allows pod CIDR on br+ interfaces.

3. `modules/nixos/beelink.nix` — Dual i226-V NICs bonded via `active-backup`
   (bond0) into a single `br0` bridge. `network-nic-performance` service applies
   TSO/GSO/SG/RX+TX offloads and RPS on both physical ports.

4. `modules/nixos/rpi.nix` — Single `end0` NIC into `br0` bridge. Same NIC
   offload service.

5. `modules/nixos/rpi5.nix` — Imports rpi.nix (inherits bridge + offloads).
   Pi5-specific: kernelboot, config.txt [pi5] section.
