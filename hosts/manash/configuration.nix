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
      "net.ipv4.conf.enp1s0.rp_filter" = 0;
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

      # This host forwards for Kubernetes/Tailscale, but still learns its WAN
      # default route via router advertisements.
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;
      "net.ipv6.conf.enp1s0.accept_ra" = 2;
      "net.ipv6.conf.enp1s0.autoconf" = 1;
      "net.ipv6.conf.enp1s0.accept_ra_defrtr" = 1;
      "net.ipv6.conf.enp1s0.accept_ra_pinfo" = 1;
      "net.ipv6.conf.enp1s0.accept_ra_mtu" = 1;
      "net.ipv6.conf.enp1s0.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv6.route.mtu_expires" = 600;
      "net.ipv6.route.min_adv_mss" = 1220;

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

  fileSystems = {
    "/mnt/flandre" = {
      label = "flandre";
      fsType = "xfs";
      options = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };

    "/mnt/remilia" = {
      label = "remilia";
      fsType = "xfs";
      options = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  networking = {
    # Long-term host policy: prefer IPv4 when a destination is reachable over
    # both families, while keeping IPv6 available. This is the NixOS-level
    # abstraction for glibc consumers and should remain even after the
    # temporary firewall workaround below is removed.
    getaddrinfo.precedence = {
      "::1/128" = 50;
      "::/0" = 40;
      "2002::/16" = 30;
      "::/96" = 20;
      "::ffff:0:0/96" = 100;
    };
    firewall = {
      enable = true;
      extraCommands = ''
        # Medium-term host policy: keep local/special-use IPv6 and the
        # cluster's internal IPv6 ranges, but reject public IPv6 egress on the
        # WAN interface so runtimes fall back to IPv4.
        ip6tables -A OUTPUT -o enp1s0 -d ::1/128 -j ACCEPT
        ip6tables -A OUTPUT -o enp1s0 -d fe80::/10 -j ACCEPT
        ip6tables -A OUTPUT -o enp1s0 -d fc00::/7 -j ACCEPT
        ip6tables -A OUTPUT -o enp1s0 -d fd00::/108 -j ACCEPT
        ip6tables -A OUTPUT -o enp1s0 -d fd01::/108 -j ACCEPT
        ip6tables -A OUTPUT -o enp1s0 -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable
      '';
      extraStopCommands = ''
        ip6tables -D OUTPUT -o enp1s0 -d ::1/128 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o enp1s0 -d fe80::/10 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o enp1s0 -d fc00::/7 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o enp1s0 -d fd00::/108 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o enp1s0 -d fd01::/108 -j ACCEPT 2>/dev/null || true
        ip6tables -D OUTPUT -o enp1s0 -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable 2>/dev/null || true
      '';
      interfaces.enp1s0 = {
        allowedTCPPorts = [
          # Kubernetes API
          6443
          # RKE2 supervisor
          9345
        ];
      };
      interfaces.tailscale0 = {
        allowedUDPPorts = [
          # Canal (Flannel VXLAN) overlay
          8472
        ];
      };
      allowedTCPPortRanges = [
        {
          # NodePort range for Services; Tailnet-restricted access is handled by
          # interfaces.enp1s0
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
    images = with config.services.rke2.package; [
      # Keep RKE2 off live registry pulls during bootstrap; this node has been
      # failing while fetching the runtime image from Docker Hub.
      images-core-linux-amd64-tar-zst
      images-canal-linux-amd64-tar-zst
      images-multus-linux-amd64-tar-zst
    ];
    nodeLabel = [ "node.longhorn.io/create-default-disk=config" ];
    extraFlags = [
      "--cluster-cidr=10.244.0.0/16,fd00::/108"
      "--cni=multus,canal"
      "--kube-controller-manager-arg=node-cidr-mask-size-ipv4=24"
      "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=112"
      "--node-ip=100.74.220.28,fd7a:115c:a1e0::8d3a:dc1c"
      "--secrets-encryption"
      "--service-cidr=10.96.0.0/12,fd01::/108"
    ];

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

    manifests = {
      rke2-canal-config.content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChartConfig";
        metadata = {
          name = "rke2-canal";
          namespace = "kube-system";
        };
        spec.valuesContent = builtins.toJSON {
          flannel.iface = "enp1s0";
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
    };
  };

  systemd.services.rke2-flux-sops-age = {
    description = "Create sops-age secret for flux-system";
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

  systemd.services.rke2-longhorn-default-disks-config = {
    description = "Apply Longhorn default-disks-config annotation";
    wants = [ "rke2-server.service" ];
    after = [ "rke2-server.service" ];
    wantedBy = [ "multi-user.target" ];
    environment.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
    serviceConfig.Type = "oneshot";
    preStart = ''
      until ${pkgs.kubectl}/bin/kubectl get node ${config.networking.hostName} >/dev/null 2>&1; do
        sleep 1
      done
    '';
    script = ''
      disk_source() {
        mount_path="$1"

        ${pkgs.util-linux}/bin/findmnt -n -o SOURCE --target "$mount_path" 2>/dev/null \
          | ${pkgs.coreutils}/bin/tail -n 1 || true
      }

      disk_tags() {
        mount_path="$1"
        source="$(disk_source "$mount_path")"

        rotational="$(${pkgs.util-linux}/bin/lsblk -ndo ROTA "$source" 2>/dev/null \
          | ${pkgs.coreutils}/bin/head -n 1 \
          | ${pkgs.gnused}/bin/sed 's/[[:space:]]//g')"

        if [ -z "$rotational" ]; then
          return 1
        elif [ "$rotational" = "1" ]; then
          printf '%s\n' '["hdd"]'
        else
          printf '%s\n' '["ssd"]'
        fi
      }

      storage_reserved() {
        mount_path="$1"
        storage_reserved_percent="$2"

        size="$(${pkgs.coreutils}/bin/df -B1 --output=size "$mount_path" \
          | ${pkgs.coreutils}/bin/tail -n 1 \
          | ${pkgs.gnused}/bin/sed 's/[[:space:]]//g')"
        printf '%s\n' "$((size * storage_reserved_percent / 100))"
      }

      disk_config_entry() {
        mount_path="$1"
        storage_reserved_percent="$2"

        if ! ${pkgs.util-linux}/bin/mountpoint -q "$mount_path"; then
          return
        fi

        tags="$(disk_tags "$mount_path")"
        if [ -z "$tags" ]; then
          return
        fi

        longhorn_path="$mount_path/longhorn"
        mkdir -p "$longhorn_path"

        ${pkgs.jq}/bin/jq -nc \
          --arg path "$longhorn_path/" \
          --argjson tags "$tags" \
          --argjson storageReserved "$(storage_reserved "$mount_path" "$storage_reserved_percent")" \
          '{
            path: $path,
            allowScheduling: true,
            storageReserved: $storageReserved,
            tags: $tags
          }'
      }

      longhornDefaultDisksConfig="$(
        {
          ${pkgs.jq}/bin/jq -nc '{
            path: "/var/lib/longhorn",
            allowScheduling: true
          }'
          for mount_path in /mnt/*; do
            if [ -d "$mount_path" ]; then
              disk_config_entry "$mount_path" 30
            fi
          done
        } | ${pkgs.jq}/bin/jq -sc '.'
      )"

      ${pkgs.kubectl}/bin/kubectl annotate node ${config.networking.hostName} \
        node.longhorn.io/default-disks-config="$longhornDefaultDisksConfig" \
        --overwrite
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
      extraUpFlags = [
        "--ssh"
        "--accept-routes"
        "--advertise-routes=10.244.0.0/16,fd00::/108"
      ];
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
