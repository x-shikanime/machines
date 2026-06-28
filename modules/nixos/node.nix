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

  networking.wireless = {
    enable = true;
    secretsFile = config.sops.templates.wifi.path;
    networks = {
      "SFR_E368".pskRaw = "ext:psk_sfr_e368";
      "SFR_E368_5SGHZ".pskRaw = "ext:psk_sfr_e368_5ghz";
      "Vintage Korean".pskRaw = "ext:psk_vintage_korean";
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
      wifi-sfr-e368.restartUnits = [ "wpa_supplicant.service" ];
      wifi-sfr-e368-5ghz.restartUnits = [ "wpa_supplicant.service" ];
      wifi-vintage-korean.restartUnits = [ "wpa_supplicant.service" ];
    };
    templates = {
      wifi = {
        content = ''
          psk_sfr_e368=${config.sops.placeholder.wifi-sfr-e368}
          psk_sfr_e368_5ghz=${config.sops.placeholder.wifi-sfr-e368-5ghz}
          psk_vintage_korean=${config.sops.placeholder.wifi-vintage-korean}
        '';
        restartUnits = [ "wpa_supplicant.service" ];
      };
    };
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    after = [ "network-online.target" ];
    description = "Enable Tailscale UDP GRO forwarding on enp1s0";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
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
}
