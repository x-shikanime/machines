{ config, ... }:

{
  imports = [
    ./minimal.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    secrets.nix-access-token.reloadUnits = [ "nix-daemon.service" ];
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  services = {
    comin = {
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

    # Defaults (cpu, cpufreq, diskstats, filesystem, loadavg, meminfo,
    # netdev, stat, systemd, processes, thermal_zone) — same set the
    # victoria-metrics-k8s-stack node-exporter DaemonSet uses on servers.
    prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "127.0.0.1";
    };

    # Victoria Metrics agent scrapes local exporters and pushes to vminsert.
    vmagent = {
      enable = true;
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "node";
            static_configs = [
              { targets = [ "127.0.0.1:9100" ]; }
            ];
          }
          {
            job_name = "comin";
            static_configs = [
              { targets = [ "127.0.0.1:4243" ]; }
            ];
          }
        ];
      };
      remoteWrite.url = "https://nishir-telemetry.taila659a.ts.net/insert/0/prometheus";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html)
  system.stateVersion = "26.05";
}
