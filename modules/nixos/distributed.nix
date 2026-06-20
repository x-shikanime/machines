{ ... }:

{
  imports = [
    ../../modules/nixos/base.nix
  ];

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    useDefaultShell = true;
  };

  nix = {
    distributedBuilds = true;
    settings = {
      builders-use-substitutes = true;
      substituters = [
        "http://ashira:5000"
        "http://manash:5000"
        "http://nalsha:5000"
        "http://fushi:5000"
        "http://minish:5000"
        "http://nemishi:5000"
      ];
    };
    buildMachines = [
      {
        hostName = "ashira";
        sshUser = "builder";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "manash";
        sshUser = "builder";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "nalsha";
        sshUser = "builder";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "fushi";
        sshUser = "builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "minish";
        sshUser = "builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "nemishi";
        sshUser = "builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" ];
        mandatoryFeatures = [ ];
      }
    ];
  };
}
