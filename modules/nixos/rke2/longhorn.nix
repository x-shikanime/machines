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
  options.shikanime.rke2.longhorn = mkOption {
    type = types.submodule {
      options = {
        enable = mkEnableOption "Longhorn integration for RKE2";

        mountRoot = mkOption {
          type = types.str;
          default = "/mnt";
          description = "The mount root scanned for additional Longhorn disks.";
        };

        storageReservedPercent = mkOption {
          type = types.int;
          default = 30;
          description = "The percentage of disk space reserved on additional Longhorn disks.";
        };
      };
    };
    default = { };
    description = "Longhorn integration for the Shikanime RKE2 stack.";
  };

  config = mkIf cfg.longhorn.enable {
    boot.kernelModules = [
      "dm_crypt"
      "iscsi_tcp"
    ];

    services.openiscsi = {
      enable = true;
      name = "iqn.2026-06.io.shikanime:${config.networking.hostName}";
    };

    boot.supportedFilesystems = [ "nfs" ];

    environment.systemPackages = with pkgs; [
      cryptsetup
      lvm2
      nfs-utils
      openiscsi
    ];

    systemd.tmpfiles.rules = [
      "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    ];

    services.rke2.nodeLabel = [
      "node.longhorn.io/create-default-disk=config"
    ];

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
      script =
        let
          mountRoot = cfg.longhorn.mountRoot;
          storageReservedPercent = toString cfg.longhorn.storageReservedPercent;
        in
        ''
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
              for mount_path in ${mountRoot}/*; do
                if [ -d "$mount_path" ]; then
                  disk_config_entry "$mount_path" ${storageReservedPercent}
                fi
              done
            } | ${pkgs.jq}/bin/jq -sc '.'
          )"

          ${pkgs.kubectl}/bin/kubectl annotate node ${config.networking.hostName} \
            node.longhorn.io/default-disks-config="$longhornDefaultDisksConfig" \
            --overwrite
        '';
    };
  };
}
