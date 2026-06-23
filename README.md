<!-- markdownlint-disable first-line-heading MD041 -->

![header.png](https://raw.githubusercontent.com/shikanime/shikanime/main/assets/github-header.png)

<!-- markdownlint-enable first-line-heading MD041 -->

# Machines

Shikanime's machine configuration repository for NixOS, nix-darwin, WSL, and
related shared home modules.

## What This Repo Contains

This flake is the source of truth for the machines I manage. It wires together:

- host-specific NixOS, nix-darwin, and WSL configurations
- shared system modules for Linux and Darwin
- shared Home Manager modules
- encrypted secrets with `sops-nix`
- distributed build and deployment helpers
- a `devenv` shell for repository tooling

## Repository Layout

### `flake.nix`

The flake entry point. It imports the module sets and exposes the host
configurations and build outputs.

### `hosts/`

Per-machine entry points.

- `hosts/<name>/configuration.nix` is the main NixOS host definition
- `hosts/telsha/darwin-configuration.nix` is the nix-darwin host definition
- `hosts/<name>/users/<user>/home-configuration.nix` contains host-specific Home
  Manager config
- `hosts/<name>/facter.json` stores hardware facts for hosts that rely on
  `nixos-facter`

Current hosts:

- `ashira` - NixOS server node
- `manash` - NixOS server node
- `nalsha` - NixOS server node
- `fushi` - NixOS ARM node
- `minish` - NixOS ARM node
- `nemishi` - NixOS ARM node
- `nixtar` - NixOS on WSL
- `catbox` - Docker image / devcontainer style NixOS build output
- `telsha` - nix-darwin host

### `modules/`

Shared module layers.

- `modules/nixos/` contains Linux host profiles
  - `base.nix` - common NixOS defaults, `comin`, and Nix access token wiring
  - `minimal.nix` - baseline Nix settings, GC, auto-upgrade, and Home Manager
    defaults
  - `workstation.nix` - workstation-oriented tooling and desktop defaults
  - `server.nix` - server defaults shared by cluster nodes
  - `distributed.nix` - remote build machines and distributed build settings
  - `node.nix` - cluster node defaults: tailscale, SSH, Avahi, firewall tweaks
  - `nishir.nix` and `talashi.nix` - cluster-specific server profiles
- `modules/darwin/` contains macOS host profiles
  - `base.nix`, `minimal.nix`, `workstation.nix`, `distributed.nix`
- `modules/home/` contains shared Home Manager modules
  - shell, editor, font, VCS, and workstation-specific settings
- `modules/flake/` contains flake-parts glue for NixOS, Darwin, and devenv

### `secrets/`

Encrypted secrets managed by `sops-nix`.

- files use the `*.enc.yaml` naming convention
- decrypted values are generated at evaluation or activation time
- do not commit plaintext secret material

### `skaffold.yaml`

Repository automation for render/build workflows.

## Flake Outputs

The flake exposes these primary outputs:

- `nixosConfigurations.ashira`
- `nixosConfigurations.manash`
- `nixosConfigurations.nalsha`
- `nixosConfigurations.fushi`
- `nixosConfigurations.minish`
- `nixosConfigurations.nemishi`
- `nixosConfigurations.nixtar`
- `darwinConfigurations.telsha`
- `packages.<system>.*` for the corresponding system builds, including `catbox`

The `packages` outputs are mostly convenience build artifacts for CI and local
verification.

## Usage

### Build A Host

```sh
nix build .#nixosConfigurations.manash.config.system.build.toplevel
nix build .#darwinConfigurations.telsha.system
```

For the published package outputs:

```sh
nix build .#packages.x86_64-linux.manash
nix build .#packages.aarch64-darwin.telsha
nix build .#packages.x86_64-linux.catbox
```

### Switch A NixOS Host

```sh
sudo nixos-rebuild switch --flake .#manash
```

Replace `manash` with `ashira`, `nalsha`, `fushi`, `minish`, `nemishi`, or
`nixtar` as needed.

### Switch A Darwin Host

```sh
darwin-rebuild switch --flake .#telsha
```

### Enter The Dev Shell

```sh
nix develop
```

The shell is defined through `devenv` and includes the repository tooling used
for build and workflow tasks.

## Secret Handling

Most hosts consume encrypted data from `secrets/<host>.enc.yaml`.

- host configs point `sops.defaultSopsFile` at their matching secret file
- secrets are restarted through systemd unit hooks where required
- some hosts also use `sops.templates.*` to materialize config fragments

## Cluster And Build Topology

The Linux server nodes are split between cluster-oriented machines and general
workstation-style machines:

- `ashira`, `manash`, and `nalsha` are x86_64 Linux nodes with Tailscale,
  distributed build settings, and cluster runner duties
- `fushi`, `minish`, and `nemishi` are ARM Linux nodes with the same shared
  cluster profile shape
- `nixtar` is a WSL-based workstation profile
- `telsha` is the Darwin workstation profile

Several hosts share remote build configuration through
`modules/nixos/distributed.nix`, which lets local builds offload work to the
other machines.

## Related Repos

This repository follows the same general shape as the other Shikanime
configuration repos:

- `x-shikanime/manifests`
- `shikanime-studio/knix`
- `x-shikanime/colemak`
