{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.shikanime.rke2;

  clusterCidr = filter (cidr: cidr != null) [
    cfg.clusterCidrIPv4
    cfg.clusterCidrIPv6
  ];

  rke2ApiServerPort = 6443;
  rke2SupervisorPort = 9345;
  kubeletMetricsPort = 10250;
  etcdClientPort = 2379;
  etcdPeerPort = 2380;
  etcdMetricsPort = 2381;
  canalHealthCheckPort = 9099;
  wireguardPort = 51820;
  wireguardIPv6Port = 51821;

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

        clusterCidrIPv4 = mkOption {
          type = types.nullOr types.str;
          default = "10.244.0.0/16";
          description = "The IPv4 pod CIDR passed to RKE2.";
        };

        clusterCidrIPv6 = mkOption {
          type = types.nullOr types.str;
          default = "fd00::/108";
          description = "The IPv6 pod CIDR passed to RKE2.";
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
        manifests = {
          rke2-canal-config.content = {
            apiVersion = "helm.cattle.io/v1";
            kind = "HelmChartConfig";
            metadata = {
              name = "rke2-canal";
              namespace = "kube-system";
            };
            spec.valuesContent = builtins.toJSON {
              flannel = {
                backend = "wireguard";
                iface = cfg.interface;
              };
              encryption = {
                enabled = true;
                type = "wireguard";
              };
              gatewayAPI = {
                enabled = true;
                gatewayClass.create = true;
              };
              hubble = {
                enabled = true;
                relay.enabled = true;
                ui.enabled = true;
              };
              ipam.mode = "kubernetes";
              k8s = {
                requireIPv4PodCIDR = cfg.clusterCidrIPv4 != null;
                requireIPv6PodCIDR = cfg.clusterCidrIPv6 != null;
              };
              k8sServiceHost = "localhost";
              k8sServicePort = "6443";
              kubeProxyReplacement = true;
              operator.prometheus.enabled = true;
              prometheus.enabled = true;
            };
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

          rke2-traefic-config.content = {
            apiVersion = "helm.cattle.io/v1";
            kind = "HelmChartConfig";
            metadata = {
              name = "rke2-traefik";
              namespace = "kube-system";
            };
            spec.valuesContent = builtins.toJSON {
              providers.kubernetesGateway.enabled = true;
            };
          };
        };
        extraFlags = [
          (optionalString (clusterCidr != [ ]) "--cluster-cidr=${concatStringsSep "," clusterCidr}")
          "--cni=multus,canal"
          "--kube-controller-manager-arg=node-cidr-mask-size-ipv4=${toString cfg.nodeCidrMaskSize}"
          "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=${toString cfg.nodeCidrMaskSizeIPv6}"
          (optionalString (cfg.serviceCidr != null) "--service-cidr=${cfg.serviceCidr}")
          "--secrets-encryption"
        ];
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
          canalHealthCheckPort
        ];
        allowedUDPPorts = [
          wireguardPort
          wireguardIPv6Port
        ];
        allowedTCPPortRanges = [ nodePortRange ];
      };
    };
  };
}
