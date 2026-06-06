{
  config,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    "${modulesPath}/virtualisation/docker-image.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/workstation.nix
  ];

  home-manager.users = {
    automata.imports = [
      ./users/automata/home-configuration.nix
    ];
    shika.imports = [
      ./users/shika/home-configuration.nix
    ];
  };

  # Prevent resolvconf from overriding Docker managed resolv.conf
  environment.etc."resolv.conf".enable = false;

  networking = {
    # Let Kubernetes manage the network configuration
    useDHCP = false;

    # Let Docker manage /etc/resolv.conf
    resolvconf.enable = false;
  };

  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  system.build.buildLayeredImage = pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/shikanime/shikanime/catbox";
    contents = [
      config.system.build.toplevel
      pkgs.bash
      pkgs.coreutils
      pkgs.dockerTools.binSh
      pkgs.findutils
      pkgs.gh
      pkgs.git
      pkgs.gnugrep
      pkgs.gnupg
      pkgs.gnused
      pkgs.gnutar
      pkgs.gzip
      pkgs.openssh
      pkgs.pass
      pkgs.stdenv
    ];
    includeNixDB = true;
    config = {
      LABELS = {
        "devcontainer.metadata" = builtins.toJSON [
          {
            containerEnv = {
              USER = "shika";
            };
            mounts = [
              {
                source = "/sys/kernel/debug";
                target = "/sys/kernel/debug";
                type = "bind";
              }
              {
                source = "/sys/kernel/tracing";
                target = "/sys/kernel/tracing";
                type = "bind";
              }
            ];
            onCreateCommand = "systemctl is-system-running --wait || true";
            overrideCommand = false;
            privileged = true;
            remoteUser = "shika";
            updateRemoteUserUID = false;
          }
        ];
        "org.opencontainers.image.source" = "https://github.com/shikanime/shikanime";
        "org.opencontainers.image.description" = "catbox development environment";
        "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
      };
      ExposedPorts."22/tcp" = { };
      Entrypoint = [ "/init" ];
    };
  };

  systemd.tmpfiles.rules = [
    "Z /workspaces - root users - -"
  ];

  users.users = {
    shika = {
      extraGroups = [ "wheel" ];
      initialHashedPassword = "";
      isNormalUser = true;
      home = "/home/shika";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6ORksXnayYquyZKEBQ8b0EEqwZRCeQFh1JlHZk9tQx"
      ];
    };

    automata = {
      initialHashedPassword = "";
      isNormalUser = true;
      home = "/home/automata";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuenA6cT5pkPEwdGvmvXRjVqFTv2QwpyYrB7gvMy0/X"
      ];
    };
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
