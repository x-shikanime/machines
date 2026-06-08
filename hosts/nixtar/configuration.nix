{
  config,
  modulesPath,
  pkgs,
  ...
}:

let
  wsl-lib = pkgs.runCommand "wsl-lib" { } ''
    mkdir -p "$out/lib"
    # # we cannot just symlink the lib directory because it breaks merging with other drivers that provide the same directory
    ln -s /usr/lib/wsl/lib/libcudadebugger.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libcuda.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libcuda.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libcuda.so.1.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libd3d12core.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libd3d12.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libdxcore.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvcuvid.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvcuvid.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvdxdlkernels.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvidia-encode.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvidia-encode.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvidia-ml.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvidia-opticalflow.so "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvidia-opticalflow.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvoptix.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libnvwgf2umx.so "$out/lib"
    ln -s /usr/lib/wsl/lib/nvidia-smi "$out/lib"
  '';
in
{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/workstation.nix
  ];

  boot = {
    # Enable cross compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      # Optimize for 64GB RAM
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.max_map_count" = 524288;

      # Increase file watcher limit for IDEs
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 512;
      "fs.file-max" = 2097152;

      # Network optimizations
      "net.core.default_qdisc" = "fq";
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 7340032;
      "net.core.rmem_max" = 16777216;
      "net.core.somaxconn" = 65535;
      "net.core.wmem_default" = 7340032;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.ip_local_port_range" = "1024 65535";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 30;
      "net.ipv4.tcp_keepalive_time" = 600;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    };
  };

  environment.systemPackages = with pkgs; [
    docker-credential-helpers
    dunst
    libnotify
    wl-clipboard
  ];

  hardware = {
    facter.reportPath = ./facter.json;
    nvidia.open = true;
    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = false;
    };
  };

  home-manager.users.shika.imports = [
    ./users/shika/home-configuration.nix
  ];

  networking.hostName = "nixtar";

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      wsl-lib
    ];
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
    };
    xserver.videoDrivers = [ "nvidia" ];
  };

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/spos-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    defaultSopsFile = ../../secrets/nixtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.nix-access-token = { };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}";
    '';
  };

  users.users.shika = {
    extraGroups = [ "wheel" ];
    home = "/home/shika";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings.features.cdi = true;
    };
  };

  wsl = {
    enable = true;
    defaultUser = "shika";
    interop.register = true;
    useWindowsDriver = true;
  };
}
