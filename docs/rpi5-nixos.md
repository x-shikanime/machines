# Raspberry Pi 5 NixOS Boot — Research & Solution

## Problem

The Raspberry Pi 5 (BCM2712) EEPROM bootloader performs an **OS check** before
loading the kernel. When it cannot find a device-tree file matching
`bcm2712-rpi-5-b.dtb` on the firmware partition, or when `config.txt` does not
signal Pi 5 support, it halts with:

```text
Device-tree file "bcm2712-rpi-5-b.dtb" not found.
The installed operating system (OS) does not indicate support for Raspberry Pi 5
Update the OS or set os_check=0 in config.txt to skip this check.
```

This affected `nemishi` (RPi 5) when building SD images via
`sd-image-aarch64.nix` with the `nixos-hardware.nixosModules.raspberry-pi-5`
module.

## Root Cause

Two independent issues:

1. **Missing DTBs in firmware partition**: The `sd-image-aarch64.nix`
   `populateFirmwareCommands` only copies Pi 3/4 DTBs (`bcm2710`, `bcm2711`) and
   U-Boot binaries. No Pi 5 DTBs (`bcm2712`).

2. **Missing `config.txt` signals**: The `config-txt-defaults.nix` in
   nixos-hardware only defines `[all]`, `[cm4]`, and `[cm5]` sections. There is
   no `[pi5]` section, no `os_check` setting, and no `arm_64bit` setting. The Pi
   5 boot ROM requires these to proceed.

## Solution: Kernelboot Bootloader

The current fix adopts the **kernelboot** pattern from
[nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi):

- The Pi 5 firmware loads `kernel.img` **directly** from the FAT firmware
  partition, bypassing the extlinux layer.
- The `os_check` is bypassed because the firmware finds a directly-loadable
  kernel image.
- `arm_64bit=1` and `os_check=0` are still included in `config.txt` as
  belt-and-suspenders.

### Firmware Partition Layout

```text
/boot/firmware/
├── bootcode.bin      # GPU boot code (from raspberrypifw)
├── start*.elf       # GPU firmware
├── fixup*.dat       # GPU fixup
├── bcm2712*.dtb     # Pi 5 device tree blobs
├── overlays/        # DTB overlays (*.dtbo)
├── kernel.img       # Linux kernel (from nixos-hardware linux-rpi)
├── initrd           # Initial ramdisk (from system.build.initialRamdisk)
├── cmdline.txt      # Kernel command line
└── config.txt       # Firmware config (with arm_64bit=1, os_check=0)
```

### Why Not `generic-extlinux-compatible`?

The `generic-extlinux-compatible` boot path uses U-Boot/extlinux to load the
kernel. The Pi 5 EEPROM `os_check` runs **before** any of that — it reads
`config.txt` directly and validates OS compatibility signals. Without
`arm_64bit=1` in a `[pi5]` section, the firmware halts.

The `kernelboot` path avoids this entirely: the firmware finds `kernel.img` in
the FAT partition and loads it directly, skipping the `os_check` validation.

## Alternative Approaches Considered

### 1. Fix `config.txt` Only (Minimal Patch)

Add `os_check=0` and `arm_64bit=1` to `config.txt` settings:

```nix
hardware.raspberry-pi.configtxt.settings.pi5 = {
  arm_64bit = 1;
  os_check = 0;
};
```

**Pros**: Minimal change. Works with existing `generic-extlinux-compatible`.
**Cons**: Still requires manual `populateFirmwareCommands` for DTBs. Fragile —
depends on the firmware's OS check behavior not changing.

### 2. Migrate Fully to `nvmd/nixos-raspberrypi`

Replace nixos-hardware entirely with:

- `boot.loader.raspberry-pi` module
- `hardware.raspberry-pi.config` for config.txt
- `hardware.raspberry-pi.firmware` for firmware staging
- Vendor kernel from `linuxPackages_rpi5`

**Pros**: Complete solution. Binary cache. Actively maintained. **Cons**: Pinned
to `nixos-25.11` (no `nixos-unstable`). Different kernel package. Would require
dropping nixos-hardware entirely.

### 3. Kernelboot with nixos-hardware Kernel (Current)

Keep nixos-hardware's `linux-rpi` kernel and `raspberry-pi-5` module. Override
`populateFirmwareCommands` to use the kernelboot pattern. Override
`populateRootCommands` to skip extlinux.

**Pros**: Minimal external dependencies. Keeps nixos-hardware kernel. Avoids
`os_check` entirely. Works with `nixos-unstable`. **Cons**:
`populateFirmwareCommands` still includes Pi 3/4 defaults from
`sd-image-aarch64.nix` (harmless but noisy).

## Upstream Status

- **nixos-hardware PR #1894** ("raspberry-pi: add firmware-partition install
  module"): Approved, awaiting merge. Adds `hardware.raspberry-pi.firmware` for
  proper firmware staging. Would eventually replace the manual
  `populateFirmwareCommands` override.
- **nixos-hardware Issue #1928**: Documents this exact bug. Created during
  previous debugging session.
- **nixpkgs Issue #260754**: Upstream tracking for Pi 5 support. NixOS
  maintainers require upstream Linux + U-Boot support before official support.

## Implementation Details

### `config.txt` Section Rendering

The nixos-hardware `config-txt.nix` renderer generates sections from nested Nix
attribute sets:

```nix
hardware.raspberry-pi.configtxt.settings.pi5 = {
  os_check = 0;
  arm_64bit = 1;
};
```

Renders to:

```ini
[pi5]
os_check=0
arm_64bit=1
```

**Important**: The settings **must** be in a `[pi5]` section, not `[all]`. The
Pi 5 firmware specifically validates model-specific settings under the correct
conditional filter.

### `populateFirmwareCommands` Evaluation Context

`populateFirmwareCommands` is evaluated at **image build time** on the target
architecture (`aarch64-linux`). The following paths are available:

- `config.system.build.kernel` — the kernel derivation
- `config.system.build.initialRamdisk` — the initrd derivation (note: **not**
  `config.system.build.initrd` — that's in `netboot.nix` only)
- `config.hardware.raspberry-pi.configtxt.file` — the rendered `config.txt`

### `populateRootCommands` Override

The default `sd-image-aarch64.nix` `populateRootCommands` references
`config.boot.loader.generic-extlinux-compatible.populateCmd`. When extlinux is
disabled, this option has no value, causing an evaluation error. The fix uses
`lib.mkForce` to override:

```nix
sdImage.populateRootCommands = lib.mkForce ''
  mkdir -p ./files/boot
'';
```

## References

- [NixOS on ARM/Raspberry Pi 5 (Wiki)](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5)
- [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi)
- [nixos-hardware Issue #1928](https://github.com/NixOS/nixos-hardware/issues/1928)
- [nixos-hardware PR #1894](https://github.com/NixOS/nixos-hardware/pull/1894)
- [nixpkgs Issue #260754](https://github.com/NixOS/nixpkgs/issues/260754)
- [Raspberry Pi config.txt documentation](https://www.raspberrypi.com/documentation/computers/config_txt.html)
