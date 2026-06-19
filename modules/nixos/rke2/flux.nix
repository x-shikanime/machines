{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.knix;
in
with lib;
{
  options.knix.flux = mkOption {
    type = types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Flux bootstrap and management for RKE2";
        };

        instance = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to deploy the Flux instance chart.";
              };

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the Flux instance chart.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-A7ojoUGwSKt+Vi+kFFroNroUxrJzHdLdbrYidHgg8gs=";
                description = "The Flux instance chart hash.";
              };

              version = mkOption {
                type = types.str;
                default = "0.46.0";
                description = "The Flux instance chart version.";
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

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the Flux operator chart.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-gt8bZ5oLw05lbUXGTzf6NBppAVuuKl9L9LH4jeROpkM=";
                description = "The Flux operator chart hash.";
              };

              version = mkOption {
                type = types.str;
                default = "0.46.0";
                description = "The Flux operator chart version.";
              };
            };
          };
          default = { };
          description = "Flux operator chart settings.";
        };

        path = mkOption {
          type = types.str;
          default = "clusters/nishir/overlays/tailnet";
          description = "The Kustomization path used by Flux.";
        };

        ref = mkOption {
          type = types.str;
          default = "refs/heads/main";
          description = "The Git ref Flux tracks.";
        };

        repoUrl = mkOption {
          type = types.str;
          default = "https://github.com/shikanime/manifests.git";
          description = "The Git repository Flux bootstraps from.";
        };

        tofu = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to deploy the tofu-controller chart.";
              };

              extraConfig = mkOption {
                type = types.attrsOf types.raw;
                default = { };
                description = "Additional raw configuration merged into the tofu-controller chart.";
              };

              hash = mkOption {
                type = types.str;
                default = "sha256-YQRWHQwNn+Du9LNcveCBzTnacRDtWNJHwvXxeIxtKcc=";
                description = "The tofu-controller chart hash.";
              };

              version = mkOption {
                type = types.str;
                default = "0.16.2";
                description = "The tofu-controller chart version.";
              };
            };
          };
          default = { };
          description = "tofu-controller chart settings.";
        };
      };
    };
    default = { };
    description = "Flux bootstrap and management for the Knix RKE2 stack.";
  };

  config = mkIf cfg.flux.enable {
    services.rke2 = {
      autoDeployCharts = mkMerge [
        (optionalAttrs cfg.flux.instance.enable {
          flux = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.instance.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.instance.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.instance.hash;
            name = "flux-instance";
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance";
            targetNamespace = "flux-system";
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
            version = cfg.flux.instance.version;
          };
        })
        (optionalAttrs cfg.flux.operator.enable {
          flux-operator = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.operator.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux-operator";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.operator.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.operator.hash;
            name = "flux-operator";
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator";
            targetNamespace = "flux-system";
            values = {
              web.config.authentication = {
                anonymous = {
                  groups = [ "system:masters" ];
                  username = "admin";
                };
                type = "Anonymous";
              };
            };
            version = cfg.flux.operator.version;
          };
        })
        (optionalAttrs cfg.flux.tofu.enable {
          tofu-controller = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.tofu.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "tofu-controller";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.tofu.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.tofu.hash;
            name = "tofu-controller";
            repo = "https://flux-iac.github.io/tofu-controller";
            targetNamespace = "flux-system";
            values = {
              awsPackage.install = false;
              runner.serviceAccount.allowedNamespaces = [
                "flux-system"
                "shikanime"
              ];
            };
            version = cfg.flux.tofu.version;
          };
        })
      ];
    };

    systemd.services.rke2-flux-sops-age = {
      after = [ "rke2-server.service" ];
      description = "Create sops-age secret for flux-system";
      environment.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
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
      serviceConfig.Type = "oneshot";
      wants = [ "rke2-server.service" ];
    };
  };
}
