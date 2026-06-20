{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./base.nix
  ];

  networking.firewall = {
    extraCommands = ''
      iptables -I INPUT -i br+ -j ACCEPT
      iptables -I FORWARD -i br+ -j ACCEPT
      ip6tables -I INPUT -i br+ -j ACCEPT
      ip6tables -I FORWARD -i br+ -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
      ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
      ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
    '';
  };

  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      rke2-token.restartUnits = [ "rke2-server.service" ];
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        addresses = true;
        enable = true;
        workstation = true;
      };
    };

    fstrim.enable = true;

    gitea-actions-runner.package = pkgs.forgejo-runner;

    nix-serve.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      enable = true;
      extraUpFlags = [ "--ssh" ];
      openFirewall = true;
      useRoutingFeatures = "server";
    };
  };

  # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
  services.tailscale.serve = {
    enable = true;
    services.nishir = {
      advertised = true;
      endpoints = {
        # Kubernetes API
        "tcp:6443" = "tcp://127.0.0.1:6443";
        # RKE2 API
        "tcp:9345" = "tcp://127.0.0.1:9345";
      };
    };
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    after = [ "network-online.target" ];
    description = "Enable Tailscale UDP GRO forwarding on enp1s0";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off
    '';
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    home = "/home/nishir";
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
