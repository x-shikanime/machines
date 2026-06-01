{
  config,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/longhorn.nix
  ];

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  boot = {
    # Kubernetes and Longhorn rely on bridge netfilter and overlayfs; BBR
    # improves WAN/Tailnet flows
    kernelModules = [
      "br_netfilter"
      "overlay"
      "tcp_bbr"
    ];
    kernel.sysctl = {
      # Raise global descriptor and watch limits for controllers, Syncthing, and
      # large media libraries
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;

      # Let bridged Kubernetes traffic traverse the iptables hooks that CNIs
      # expect
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;

      # Favor low-latency queueing and larger bursts for overlay traffic and
      # busy services
      "net.core.default_qdisc" = "fq";
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 7340032;
      "net.core.rmem_max" = 16777216;
      "net.core.somaxconn" = 4096;
      "net.core.wmem_default" = 7340032;
      "net.core.wmem_max" = 16777216;

      # Keep forwarding and TCP autotuning friendly to k0s, Tailscale, and
      # service fan-out
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.tailscale0.rp_filter" = 0;
      "net.ipv4.ip_local_port_range" = "1024 65535";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 15;
      "net.ipv4.tcp_keepalive_time" = 600;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.neigh.default.gc_thresh1" = 1024;
      "net.ipv4.neigh.default.gc_thresh2" = 2048;
      "net.ipv4.neigh.default.gc_thresh3" = 4096;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;

      # Increase conntrack room for NAT, service meshes, and
      # clustered east-west traffic
      "net.netfilter.nf_conntrack_max" = 262144;

      # Reduce swap thrash and preserve cache behavior on a mixed storage/media
      # node
      "vm.dirty_background_ratio" = 3;
      "vm.dirty_expire_centisecs" = 1000;
      "vm.dirty_ratio" = 10;
      "vm.dirty_writeback_centisecs" = 500;
      "vm.max_map_count" = 262144;
      "vm.page-cluster" = 0;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 200;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  disko.devices = {
    disk.main = {
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
  };

  hardware.facter.reportPath = ./facter.json;

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  networking = {
    firewall = {
      enable = true;
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          # Kubernetes API
          6443
          # RKE2 supervisor
          9345
        ];
        allowedUDPPorts = [
          # Canal (Flannel VXLAN) overlay
          8472
        ];
      };
      allowedTCPPortRanges = [
        {
          # NodePort range for Services; Tailnet-restricted access is handled by
          # interfaces.tailscale0
          from = 30000;
          to = 32767;
        }
      ];
    };
    hostName = "manash";
  };

  services.rke2 = {
    enable = true;
    role = "server";
    cisHardening = true;
    extraFlags = [
      "--cluster-cidr=10.42.0.0/16,2001:cafe:42::/56"
      "--secrets-encryption"
      "--service-cidr=10.43.0.0/16,2001:cafe:43::/112"
    ];

    cni = "canal";

    # Let kubelet and RKE2 drain workloads cleanly on shutdown/reboot.
    gracefulNodeShutdown.enable = true;

    autoDeployCharts = {
      flux = {
        repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance";
        name = "flux-instance";
        hash = "sha256-A7ojoUGwSKt+Vi+kFFroNroUxrJzHdLdbrYidHgg8gs=";
        version = "0.46.0";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          instance = {
            distribution = {
              registry = "ghcr.io/fluxcd";
              version = "2.x";
            };
            kustomize = {
              patches = [
                {
                  patch = ''
                    - op: add
                      path: /spec/decryption
                      value:
                        provider: sops
                        secretRef:
                          name: sops-age
                  '';
                  target.kind = "Kustomization";
                }
              ];
            };
            sync = {
              interval = "1m";
              kind = "GitRepository";
              path = "clusters/nishir/overlays/tailnet";
              pullSecret = "";
              ref = "refs/heads/main";
              url = "https://github.com/shikanime/manifests.git";
            };
          };
        };
      };

      flux-operator = {
        repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator";
        name = "flux-operator";
        hash = "sha256-gt8bZ5oLw05lbUXGTzf6NBppAVuuKl9L9LH4jeROpkM=";
        version = "0.46.0";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          healthcheck.enabled = true;
          web = {
            config.authentication = {
              type = "Anonymous";
              anonymous = {
                username = "admin";
                groups = [ "system:masters" ];
              };
            };
            ingress = {
              enabled = true;
              className = "tailscale";
              annotations."tailscale.com/tags" = "tag:web";
              hosts = [
                {
                  host = "nishir-flux";
                  paths = [
                    {
                      path = "/";
                      pathType = "ImplementationSpecific";
                    }
                  ];
                }
              ];
              tls = [
                {
                  hosts = [ "nishir-flux" ];
                }
              ];
            };
            rbac.createRoles = true;
          };
        };
      };

      tofu-controller = {
        repo = "https://flux-iac.github.io/tofu-controller";
        name = "tofu-controller";
        hash = "sha256-YQRWHQwNn+Du9LNcveCBzTnacRDtWNJHwvXxeIxtKcc=";
        version = "0.16.2";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          awsPackage.install = false;
          runner.allowedNamespaces = [
            "flux-system"
            "shikanime"
          ];
        };
      };
    };

    manifests.rke2-canal-config.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChartConfig";
      metadata = {
        name = "rke2-canal";
        namespace = "kube-system";
      };
      spec.valuesContent = builtins.toJSON {
        flannel.iface = "tailscale0";
      };
    };
  };

  systemd.services.rke2-sops-age = {
    wants = [ "rke2-server.service" ];
    after = [ "rke2-server.service" ];
    environment.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
    serviceConfig.Type = "oneshot";
    preStart = ''
      until ${pkgs.kubectl}/bin/kubectl get namespace flux-system >/dev/null 2>&1; do
        sleep 1
      done
    '';
    script = ''
      if ! ${pkgs.kubectl}/bin/kubectl -n flux-system get secret sops-age >/dev/null 2>&1; then
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | \
          ${pkgs.kubectl}/bin/kubectl -n flux-system create secret generic sops-age \
            --from-file=age.agekey=/dev/stdin \
            --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
      fi
    '';
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      extraUpFlags = [ "--ssh" ];
      useRoutingFeatures = "server";
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      tailscale-authkey = { };
      nix-config = { };
    };
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/nishir";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
