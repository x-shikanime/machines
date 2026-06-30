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

### Step 1: Patch the flannel ConfigMap (pre-existing)

WARNING: FluxCD may revert this if the HelmRelease manages this ConfigMap.
Verify before/after that the change persists. If Flux reverts, the backend must
be set via the RKE2 HelmChartConfig or the victoria-metrics-k8s-stack chart
values.

```bash
# Current config
kubectl get cm -n kube-system rke2-canal-config -o yaml | grep -A2 Backend

# Apply patch
kubectl patch cm -n kube-system rke2-canal-config \
  --type merge \
  --patch '{"data":{"net-conf.json":"{\"Network\":\"10.244.0.0/16\",\"IPv6Network\":\"fd00::/108\",\"EnableIPv6\":true,\"Backend\":{\"Type\":\"host-gw\"}}"}}'
```

### Step 2: Restart canal DaemonSet on each node (one at a time)

```bash
# Restart canal pods rolling — each node's pod will pick up the new config
kubectl rollout restart ds -n kube-system rke2-canal

# Verify all canal pods are running with the new backend
kubectl get pods -n kube-system -l app=flannel -o wide
```

### Step 3: Restart RKE2 rolling (to pick up new CNI config)

For each node:

```bash
# SSH to node (or use tailscale-ssh)
sudo systemctl restart rke2-server   # on control-plane nodes
sudo systemctl restart rke2-agent    # on worker nodes

# Wait for node + pods rescheduled before moving to next node
kubectl wait --for=condition=Ready node/<name> --timeout=120s
```

### Step 4: Verify

```bash
# Confirm flannel routing uses host-gw (direct routes, no wg encapsulation)
ip route | grep 10.244
# Expected: direct via <interface> via <gateway-IP>, NOT via flannel.X device

# Run cross-node iperf3 (from monitoring-system namespace)
kubectl apply -f docs/iperf3-test.yaml
# Check throughput — should see > 2 Gbps on Beelink, > 900 Mbps on Pi4
```

### Alternative if Flux reverts

If FluxCD HelmRelease manages the canal config and reverts the patch:

1. Create a `HelmChartConfig` CR in `kube-system` namespace:

   ```yaml
   apiVersion: helm.cattle.io/v1
   kind: HelmChartConfig
   metadata:
     name: rke2-canal
     namespace: kube-system
   spec:
     valuesContent: |
       flannel:
         backend: host-gw
   ```

2. Or change the RKE2 cluster template in `Chef/Rancher` to use host-gw.

## Expected Results After All Remediations Combined

| Path                | Current (wireguard) | After host-gw | After +offloads | Target (80%) |
| ------------------- | ------------------- | ------------- | --------------- | ------------ |
| Beelink <-> Beelink | ~535 Mbps           | ~2,200 Mbps   | ~2,400 Mbps     | 2,000 Mbps   |
| Pi4 <-> Pi4         | ~400 Mbps           | ~900 Mbps     | ~940 Mbps       | 800 Mbps     |
| Beelink <-> Pi4     | ~450 Mbps           | ~1,500 Mbps   | ~1,800 Mbps     | —            |

## Related Changes (in this PR)

1. `modules/nixos/node.nix` — Firewall now allows pod CIDR (10.244.0.0/16) on
   physical interfaces, enabling cross-node pod↔host communication (fixes
   vmagent node-exporter scraping, 4 of 5 targets were DOWN).

2. `modules/nixos/beelink.nix` — Replaced `tailscale-udp-gro-forwarding` with
   `network-nic-performance` enabling TSO, GSO, scatter-gather, TX/RX checksum
   offloads, and RPS across all CPU cores.

3. `modules/nixos/rpi.nix` — Same improvement: GRO + TSO + GSO + RPS for Pi
   NICs.
