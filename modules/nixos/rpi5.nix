{
  # Older Raspberry Pi-class boards still need these cgroup knobs for RKE2.
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
