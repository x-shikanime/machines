{ config, pkgs, ... }:

let
  # Defaults (cpu, cpufreq, diskstats, filesystem, loadavg, meminfo,
  # netdev, stat, systemd, processes, thermal_zone) — same set the
  # victoria-metrics-k8s-stack node-exporter DaemonSet uses on servers.
  vmagentConfig = pkgs.writeText "vmagent.yml" ''
    scrape_configs:
      - job_name: "node"
        static_configs:
          - targets: ["127.0.0.1:9100"]
      - job_name: "comin"
        static_configs:
          - targets: ["127.0.0.1:4243"]
  '';
in
{
  imports = [
    ./minimal.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    secrets.nix-access-token = { };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  services.comin = {
    enable = true;
    # Node exporter listens on localhost only — vmagent scrapes from 127.0.0.1.
    exporter.listen_address = "127.0.0.1";
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shikanime-labs/machines.git";
      }
    ];
  };

  launchd.daemons = {
    node-exporter = {
      command = "${pkgs.prometheus-node-exporter}/bin/node_exporter --web.listen-address=127.0.0.1:9100";
      serviceConfig = {
        Label = "org.nixos.node-exporter";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/node-exporter.log";
        StandardErrorPath = "/var/log/node-exporter.log";
      };
    };
    vmagent = {
      command = ''
        ${pkgs.victoriametrics}/bin/vmagent \
          -promscrape.config=${vmagentConfig} \
          -remoteWrite.url=https://nishir-telemetry.taila659a.ts.net/insert/0/prometheus
      '';
      serviceConfig = {
        Label = "org.nixos.vmagent";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/vmagent.log";
        StandardErrorPath = "/var/log/vmagent.log";
      };
    };
  };
}
