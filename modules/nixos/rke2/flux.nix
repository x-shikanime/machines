{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.shikanime.rke2;
in
with lib;
{
  options.shikanime.rke2.flux = mkOption {
    type = types.submodule {
      options = {
        enable = mkEnableOption "Flux bootstrap and management for RKE2";

        repoUrl = mkOption {
          type = types.str;
          default = "https://github.com/shikanime/manifests.git";
          description = "The Git repository Flux bootstraps from.";
        };

        ref = mkOption {
          type = types.str;
          default = "refs/heads/main";
          description = "The Git ref Flux tracks.";
        };

        path = mkOption {
          type = types.str;
          default = "clusters/nishir/overlays/tailnet";
          description = "The Kustomization path used by Flux.";
        };

        instance = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to deploy the Flux instance chart.";
              };

              version = mkOption {
                type = types.str;
                default = "0.46.0";
                description = "The Flux instance chart version.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-A7ojoUGwSKt+Vi+kFFroNroUxrJzHdLdbrYidHgg8gs=";
                description = "The Flux instance chart hash.";
              };

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the Flux instance chart.";
              };
            };
          };
          default = { };
          description = "Flux instance chart settings.";
        };

        operator = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to deploy the Flux operator chart.";
              };

              version = mkOption {
                type = types.str;
                default = "0.46.0";
                description = "The Flux operator chart version.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-gt8bZ5oLw05lbUXGTzf6NBppAVuuKl9L9LH4jeROpkM=";
                description = "The Flux operator chart hash.";
              };

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the Flux operator chart.";
              };
            };
          };
          default = { };
          description = "Flux operator chart settings.";
        };

        tofu = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to deploy the tofu-controller chart.";
              };

              version = mkOption {
                type = types.str;
                default = "0.16.2";
                description = "The tofu-controller chart version.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-YQRWHQwNn+Du9LNcveCBzTnacRDtWNJHwvXxeIxtKcc=";
                description = "The tofu-controller chart hash.";
              };

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the tofu-controller chart.";
              };
            };
          };
          default = { };
          description = "tofu-controller chart settings.";
        };
      };
    };
    default = { };
    description = "Flux bootstrap and management for the Shikanime RKE2 stack.";
  };

  config = mkIf cfg.flux.enable {
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

    services.rke2 = {
      autoDeployCharts = mkMerge [
        (optionalAttrs cfg.flux.instance.enable {
          flux = {
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance";
            name = "flux-instance";
            hash = cfg.flux.instance.hash;
            version = cfg.flux.instance.version;
            targetNamespace = "flux-system";
            createNamespace = true;
            values = {
              instance = {
                distribution = {
                  registry = "ghcr.io/fluxcd";
                  version = "2.x";
                };
                kustomize.patches = [
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
                sync = {
                  interval = "1m";
                  kind = "GitRepository";
                  path = cfg.flux.path;
                  pullSecret = "";
                  ref = cfg.flux.ref;
                  url = cfg.flux.repoUrl;
                };
              };
            };
          };
        })
        (optionalAttrs cfg.flux.operator.enable {
          flux-operator = {
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator";
            name = "flux-operator";
            hash = cfg.flux.operator.hash;
            version = cfg.flux.operator.version;
            targetNamespace = "flux-system";
            createNamespace = true;
            values = {
              healthcheck.enabled = true;
              web.config.authentication = {
                anonymous = {
                  username = "admin";
                  groups = [ "system:masters" ];
                };
                type = "Anonymous";
                rbac.createRoles = true;
              };
            };
          };
        })
        (optionalAttrs cfg.flux.tofu.enable {
          tofu-controller = {
            repo = "https://flux-iac.github.io/tofu-controller";
            name = "tofu-controller";
            hash = cfg.flux.tofu.hash;
            version = cfg.flux.tofu.version;
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
        })
      ];

      manifests = mkMerge [
        (optionalAttrs cfg.flux.instance.enable {
          flux-config = {
            content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux";
                namespace = "kube-system";
              };
              spec = {
                values = cfg.flux.instance.extraConfig;
              };
            };
          };
        })
        (optionalAttrs cfg.flux.operator.enable {
          flux-operator-config = {
            content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux-operator";
                namespace = "kube-system";
              };
              spec = {
                values = cfg.flux.operator.extraConfig;
              };
            };
          };
        })
        (optionalAttrs cfg.flux.tofu.enable {
          tofu-controller-config = {
            content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "tofu-controller";
                namespace = "kube-system";
              };
              spec = {
                values = cfg.flux.tofu.extraConfig;
              };
            };
          };
        })
      ];
    };
  };
}
