# nixos-config

Personal Nix flake for all my machines: NixOS hosts plus nix-darwin Macs. Every
host shares one set of modules and one home-manager profile. There is no CI or
build server: each host rebuilds itself from this repo.

## Hosts

| Host | Arch | Role | Machine file |
|---|---|---|---|
| `desktop` | x86_64 | AMD workstation and gaming PC: hot-swap LUKS drives, SnapRAID/mergerfs backup set, ollama (ROCm) | `machine/desktop.nix` |
| `framework` | x86_64 | Framework 12th-gen laptop: throttled, fw-fanctrl, hibernate | `machine/framework.nix` |
| `thinkpad` | x86_64 | X1 Extreme laptop: NVIDIA PRIME offload, thinkfan, Sunshine | `machine/thinkpad.nix` |
| `mini` | x86_64 | LAN server: Samba/Time Machine, borg target for all hosts | `machine/mini.nix` |
| `homeserver` | x86_64 | LAN server: Frigate (Coral TPU), Samba, VirtualBox | `machine/homeserver.nix` |
| `vps-arm` | aarch64 | Public VPS: nginx + self-hosted services, AdGuard DNS, WireGuard, fail2ban | `machine/vps-arm.nix` |
| `nixos-vm` | aarch64 | Test VM | `machine/nixos-vm/` |
| `nixos-vm-fusion` | aarch64 | VMware Fusion VM | `machine/nixos-vm-fusion.nix` |
| `nixos-virtualbox` | x86_64 | VirtualBox VM (**doesn't evaluate at the moment**: `postResumeCommands` vs. systemd stage 1) | `machine/nixos-virtualbox/` |
| `MacBook`, `MacbookProM1` | aarch64-darwin | nix-darwin, both use the same file | `machine/macbook.nix` |

## Layout

```
flake.nix            inputs + host list; mkNixosHost adds sops-nix, impermanence, home-manager
machine/<host>.nix   per-host entry point: hostname, boot/LUKS, disks, secrets, imports
configs/             shared modules, imported selectively by machine files
configs/services/    one module per self-hosted service (mostly imported by vps-arm)
configs/home.nix     the single home-manager profile for every host (zsh/p10k, tmux, git, ssh)
home/                dotfiles + scripts linked into ~/.bin
secrets/             sops-encrypted YAML: secrets.yaml (shared) + secrets-<host>.yaml
overlays/, pkgs/     custom packages (pkgs.psensor) and overlays (opt-in per host)
scripts/             maintenance helpers (see below)
backup/              retired modules, not imported
```

### Shared modules worth knowing

| Module | What it does |
|---|---|
| `common.nix` / `common-linux.nix` | base packages, known hosts / Linux base: GRUB, sops, nix settings, SSH, dnscrypt, persistence |
| `user.nix`, `user-gui.nix` | user `alex` (password from sops, keys from `ssh-keys.nix`) / desktop apps |
| `ssh-keys.nix` | the only place SSH public keys live (`personal`, `borg`, `initrd`) |
| `filesystem.nix` | btrfs-on-LVM subvolume layout (`root`, `home`, `nix`, `persist`, `log`) |
| `lan-server.nix` | mini + homeserver: initrd SSH, Tailscale routing, firewall off |
| `initrd-ssh.nix` | SSH in the initrd to unlock LUKS remotely (port 22) |
| `borg.nix` | daily borg job; key `borg-key` from `secrets-<hostname>.yaml`, the host sets `repo` |
| `samba.nix` + `samba-shares.nix` | Samba server + presets: `shares.share "<path>"`, `shares.timeMachine "<path>"` |
| `nginx-vhosts.nix` | `vhosts.proxy "http://127.0.0.1:<port>/"`: HTTPS + ACME + websocket reverse proxy |
| `plasma*.nix`, `games.nix`, `develop.nix`, `docker.nix`, … | feature modules, imported as needed |

Hosts with impermanence wipe the root filesystem on boot. Only paths listed in
`environment.persistence."/persist"` survive.

## Everyday commands

```sh
sudo nixos-rebuild switch --flake .               # apply on the current host
sudo nixos-rebuild switch --flake .#<host>        # pick a host explicitly
darwin-rebuild switch --flake .#MacBook           # macOS
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link   # check that it builds

nix flake update                                  # bump all inputs
alejandra .                                       # format (Claude Code does this automatically on edit)
scripts/commit.sh                                 # commit as <hostname>-<date>-<time>

sops secrets/secrets-<host>.yaml                  # edit secrets
sudo nix-collect-garbage -d                       # GC (nh also cleans automatically, keeps 14 days)
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

## How to …

- **Add a host:** create `machine/<host>.nix`, then add `mkNixosHost { system; hostModules = [<hardware profiles> ./machine/<host>.nix]; }` to `flake.nix`. For secrets, get the host's age key (`scripts/hostkey-to-agepub.sh`), add it to `.sops.yaml` and create `secrets/secrets-<host>.yaml`.
- **Add a self-hosted service:** add `configs/services/<name>.nix` (persistence dirs, `vhosts.proxy` for nginx) and import it from `machine/vps-arm.nix`.
- **Add a Samba share:** `services.samba.settings.<name> = shares.share "/path";` on a host that imports `samba.nix`.
- **Rotate an SSH key:** edit `configs/ssh-keys.nix` and rebuild the affected hosts.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/commit.sh` | `git commit` with a `<hostname>-<date>-<time>` message |
| `scripts/trim-generations.sh <gens> <days> <profile>` | delete old generations (interactive) |
| `scripts/hostkey-to-agepub.sh` | print this host's SSH host key as an age public key, for `.sops.yaml` |
| `scripts/encrypt-backup-disk.sh <disk>` | encrypt one desktop SnapRAID disk in place (LUKS2) |
| `scripts/set-permissions.sh USER GROUP [PATH]` | recursive chown, dirs 755 / files 644 |
| `scripts/btrfs-list` | tree view of btrfs subvolumes and snapshots |
| `scripts/fs-diff.sh` | list files changed on the root subvolume since `root-blank` |
| `scripts/defrag.sh` | defragment heavily fragmented files (>1000 extents) in `~/shared/storage` |
| `scripts/postgres-password` | generate a SCRAM-SHA-256 hash for a Postgres password |
| `scripts/brew-packages-manual-upgrade.sh` | list Homebrew casks that `brew upgrade` skips |
| `~/.bin/storage-hotswap` | desktop: `status` / `rescan` / `mount` / `eject` the hot-swap LUKS drives |
| `~/.bin/power-draw [-w]` | desktop: current CPU + GPU power draw |
| `~/.bin/backup-to-stick` | rsync Workspace / Sync / Kamera to the USB stick |
| `~/.bin/git-redate`, `~/.bin/trim-check` | rewrite commit dates / check that SSD TRIM works |
