{
  imports = [
    ./rpi.nix
  ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;

  # VL805 xHCI stability mitigations
  boot.kernelParams = [
    # Disable xHCI streams - causes "unknown stream ring" errors on VL805
    "xhci-hcd.quirk_usb2_inst_suspend=0"
    # Disable ASPM to reduce PCIe link power transitions
    "pcie_aspm=off"
  ];

  # Disable UAS for external USB drives - use more stable usb-storage
  # Blacklist UAS kernel module to prevent crashes on VL805
  boot.blacklistedKernelModules = [ "uas" ];
}
