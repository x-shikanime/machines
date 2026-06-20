{
  nix = {
    distributedBuilds = true;

    settings = {
      builders-use-substitutes = true;
      substituters = [
        "https://ashira.taila659a.ts.net:5000"
        "https://manash.taila659a.ts.net:5000"
        "https://nalsha.taila659a.ts.net:5000"
        "https://fushi.taila659a.ts.net:5000"
        "https://minish.taila659a.ts.net:5000"
        "https://nemishi.taila659a.ts.net:5000"
      ];
    };

    buildMachines = [
      {
        hostName = "ashira.taila659a.ts.net";
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
        hostName = "manash.taila659a.ts.net";
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
        hostName = "nalsha.taila659a.ts.net";
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
        hostName = "fushi.taila659a.ts.net";
        sshUser = "builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "minish.taila659a.ts.net";
        sshUser = "builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "nemishi.taila659a.ts.net";
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
