{
  config,
  lib,
  ...
}:

let
  cfg = config.shikanime.rke2;

  rke2ApiServerPort = 6443;
  rke2SupervisorPort = 9345;
  kubeletMetricsPort = 10250;
  etcdClientPort = 2379;
  etcdPeerPort = 2380;
  etcdMetricsPort = 2381;
  ciliumHealthPort = 9890;
  wireguardPort = 51820;
  gatewayAPIPort = 8443;

  nodePortRange = {
    from = 30000;
    to = 32767;
  };
in
with lib;
{
  imports = [
    ./longhorn.nix
    ./flux.nix
  ];

  options.shikanime.rke2 = mkOption {
    type = types.submodule {
      options = {
        enable = mkEnableOption "Shikanime RKE2";

        clusterCidrs = mkOption {
          type = types.nullOr types.str;
          default = "10.244.0.0/16,fd00::/108";
          description = "The pod CIDR passed to RKE2.";
        };

        cni = mkOption {
          type = types.listOf types.str;
          default = [
            "multus"
            "cilium"
          ];
          description = "The CNI plugins passed to RKE2.";
        };

        nodeCidrMaskSize = mkOption {
          type = types.int;
          default = 24;
          description = "The IPv4 node CIDR mask size passed to the controller manager.";
        };

        nodeCidrMaskSizeIPv6 = mkOption {
          type = types.int;
          default = 112;
          description = "The IPv6 node CIDR mask size passed to the controller manager.";
        };

        secretsEncryption = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable RKE2 secrets encryption.";
        };

        serviceCidr = mkOption {
          type = types.nullOr types.str;
          default = "10.96.0.0/12,fd01::/108";
          description = "The service CIDR passed to RKE2.";
        };

        interface = mkOption {
          type = types.str;
          default = "enp1s0";
          description = "The WAN interface used for firewall policy.";
        };

        extraConfig = mkOption {
          type = types.attrsOf types.raw;
          default = { };
          description = "Additional direct values merged into services.rke2.";
        };
      };
    };
    default = { };
    description = "Structured configuration for the Shikanime RKE2 stack.";
  };

  config = mkIf cfg.enable {
    services.rke2 = mkMerge [
      {
        enable = true;
        role = "server";
        cisHardening = true;
        disableKubeProxy = true;
        manifests = {
          rke2-cilium-config.content = {
            apiVersion = "helm.cattle.io/v1";
            kind = "HelmChartConfig";
            metadata = {
              name = "rke2-cilium";
              namespace = "kube-system";
            };
            spec.valuesContent = builtins.toJSON {
              kubeProxyReplacement = true;
              k8sServiceHost = "localhost";
              k8sServicePort = "6443";
              encryption.enabled = true;
              encryption.type = "wireguard";
              cni.chainingMode = "multus";
              cni.exclusive = false;
              autoDirectNodeRoutes = true;
              gatewayAPI.enabled = true;
              hubble.enabled = true;
              hubble.relay.enabled = true;
              hubble.ui.enabled = true;
              prometheus.enabled = true;
              operator.prometheus.enabled = true;
              bpf.masquerade = true;
              ipv4NativeRoutingCIDR = "10.244.0.0/16";
              ipam.operator.clusterPoolIPv4PodCIDRList = [
                "10.244.0.0/16"
              ];
            };
          };

          rke2-cilium-gateway-class.content = {
            apiVersion = "networking.x-k8s.io/v1";
            kind = "GatewayClass";
            metadata.name = "rke2-cilium";
            spec.controllerName = "cilium.io/gateway-controller";
          };

          rke2-coredns-config.content = {
            apiVersion = "helm.cattle.io/v1";
            kind = "HelmChartConfig";
            metadata = {
              name = "rke2-coredns";
              namespace = "kube-system";
            };
            spec.valuesContent = builtins.toJSON {
              nodelocal.enabled = true;
            };
          };

          rke2-multus-config.content = {
            apiVersion = "helm.cattle.io/v1";
            kind = "HelmChartConfig";
            metadata = {
              name = "rke2-multus";
              namespace = "kube-system";
            };
            spec.valuesContent = builtins.toJSON {
              manifests.dhcpDaemonSet = true;
            };
          };
        };
        extraFlags = [
          (optionalString (cfg.clusterCidrs != null) "--cluster-cidr=${cfg.clusterCidrs}")
          "--cni=${concatStringsSep "," cfg.cni}"
          "--kube-controller-manager-arg=node-cidr-mask-size-ipv4=${toString cfg.nodeCidrMaskSize}"
          "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=${toString cfg.nodeCidrMaskSizeIPv6}"
          (optionalString (cfg.serviceCidr != null) "--service-cidr=${cfg.serviceCidr}")
        ]
        ++ optional cfg.secretsEncryption "--secrets-encryption";
        gracefulNodeShutdown.enable = true;
      }
      cfg.extraConfig
    ];

    networking.firewall = {
      extraCommands = ''
        # Keep public IPv6 egress off the WAN interface so runtimes fall back
        # to IPv4 while still allowing local and tailnet traffic.
        ip6tables -A OUTPUT -o ${cfg.interface} -d ::1/128 -j ACCEPT
        ip6tables -A OUTPUT -o ${cfg.interface} -d fe80::/10 -j ACCEPT
        ip6tables -A OUTPUT -o ${cfg.interface} -d fc00::/7 -j ACCEPT
        ip6tables -A OUTPUT -o ${cfg.interface} -d fd00::/108 -j ACCEPT
        ip6tables -A OUTPUT -o ${cfg.interface} -d fd01::/108 -j ACCEPT
        ip6tables -A OUTPUT -o ${cfg.interface} -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable
      '';
      extraStopCommands = ''
        ip6tables -D OUTPUT -o ${cfg.interface} -d ::1/128 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o ${cfg.interface} -d fe80::/10 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o ${cfg.interface} -d fc00::/7 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o ${cfg.interface} -d fd00::/108 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o ${cfg.interface} -d fd01::/108 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o ${cfg.interface} -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable 2>/dev/null || true
      '';
      interfaces.${cfg.interface} = {
        allowedTCPPorts = [
          rke2ApiServerPort
          rke2SupervisorPort
          kubeletMetricsPort
          etcdClientPort
          etcdPeerPort
          etcdMetricsPort
          ciliumHealthPort
          gatewayAPIPort
        ];
        allowedUDPPorts = [
          wireguardPort
        ];
        allowedTCPPortRanges = [ nodePortRange ];
      };
    };
  };
}
