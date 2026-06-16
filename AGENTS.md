# Shikanime

NixOS and nix-darwin configuration flake managing all Shikanime infrastructure
hosts, modules, and secrets.

**Language:** Nix

## Structure

- `flake.nix` — Top-level flake aggregating all hosts, modules, and overlays
- `hosts/` — Per-host NixOS/nix-darwin configurations
  - `ashira/`, `catbox/`, `fushi/`, `kaltashar/`, `manash/`, `minish/`,
    `nemishi/`, `nalsha/`, `nixtar/`, `telsha/`
- `modules/` — Shared Nix modules (darwin, flake, home-manager, nixos)
- `infra/` — Infrastructure definitions (GitHub, Google Cloud, HCP)
- `secrets/` — SOPS-encrypted secrets
- `assets/` — Static assets (images, etc.)

## Host Naming

Japanese-sounding names ending in `-a` or `-i`. Mount points use Touhou
character names (`marisa`, `reimu`, `flandre`, `remilia`, `patchouli`,
`nishir`).

## Commit Style

- Plain-text capitalized title, no conventional-commit prefix
- Body with labels: `Design:`, `Related:`, `Closes #`
- Keep Markdown lines wrapped at 80 columns and run `nix fmt` before shipping

## Stack

- 1 commit == 1 PR via ghstack
- Amend + `ghstack` to resubmit
- `ghstack land` on head PR to land the entire stack
- Never `gh pr merge` (creates poisoned commits)
- Never force-push ghstack branches
- ghstack only works on HEAD commit chains, not detached HEADs

## Protect `main`

- Require 1 approving review
- Require linear history (no merge commits)
- Require signed commits
- Squash+rebase merge only

## Nix Conventions

- Use `devenv` + `flake.nix` + `direnv` for local development
- `nix fmt` via treefmt before committing
- Hosts import from `modules/` — keep shared logic in modules, host-specific
  config in `hosts/<name>/`
- Raspberry Pi: `hardware.raspberry-pi` module removed from nixpkgs unstable;
  use `hardware.enableRedistributableFirmware` instead
- SD card images via `sd-image-aarch64.nix`; `nixos-raspberrypi` repo deprecated
  on unstable
- Nix flakes not enabled by default on macOS — add
  `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf`
  or prefix commands with `NIX_CONFIG`

## Tooling

- `gh` at `/opt/local/bin/gh`
- `ghstack` at `~/.hermes/hermes-agent/venv/bin/ghstack`
- GPG key: `5942C2A7CB4C5DD8CFE6600513FD2FB130B3B762` (ed25519, no passphrase)
- `pinentry-tty` + `allow-loopback-pinentry` configured
- SSH signing does NOT show GitHub "Verified" — use GPG when verified status
  required

## Secrets

- Managed via SOPS — never commit plaintext secrets
- Decrypt with `sops` before editing, re-encrypt after

*Licensed under AGPL-3.0. Test configurations with `nix flake check` before
submitting. Always use worktrees when making changes — never commit directly
from the main checkout.*
