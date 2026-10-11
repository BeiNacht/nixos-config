#!/usr/bin/env bash
# WIPE disks of the SnapRAID backup set and set them up fresh:
#
#   sudo ./scripts/format-backup-disks.sh <disk1|disk2|disk3|parity>...
#
# Each disk's first partition gets LUKS2 (label <disk>-crypt, key
# /persist/backup-hdd.key) with btrfs (data disks) or ext4 (parity) on top,
# matching configs/backup-disks.nix.
# All data on the named disks is destroyed.
set -euo pipefail

key=/persist/backup-hdd.key
pool=/home/alex/shared/backup

if (($# == 0)); then
  echo "usage: $0 <disk1|disk2|disk3|parity>..." >&2
  exit 1
fi
for name in "$@"; do
  case "$name" in
    disk1 | disk2 | disk3 | parity) ;;
    *)
      echo "unknown disk: $name" >&2
      exit 1
      ;;
  esac
done
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

unit() { systemd-escape --path --suffix="$2" "$1"; }

# The partition, by LUKS label (already encrypted) or by fs label (plain ext4).
find_dev() {
  local link
  for link in "/dev/disk/by-label/$1-crypt" "/dev/disk/by-label/$1"; do
    if [[ -e "$link" ]]; then
      readlink -f "$link"
      return
    fi
  done
  return 1
}

declare -A devs
for name in "$@"; do
  dev="$(find_dev "$name")" || {
    echo "$name not found (no partition labelled $name-crypt or $name) - is it plugged in?" >&2
    exit 1
  }
  if [[ "$dev" == /dev/dm-* ]]; then
    echo "$name resolves to $dev, a device-mapper device - check lsblk" >&2
    exit 1
  fi
  devs[$name]="$dev"
done

echo "About to DESTROY ALL DATA on:"
for name in "$@"; do
  dev="${devs[$name]}"
  disk="/dev/$(lsblk -no PKNAME "$dev" | head -n1)"
  echo
  echo "  $name -> $dev"
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL,SERIAL "$disk" | sed 's/^/    /'
done
echo
read -rp "Type 'wipe $*' to continue: " answer
[[ "$answer" == "wipe $*" ]] || exit 1

if [[ ! -e "$key" ]]; then
  echo "Creating $key"
  (umask 077 && dd if=/dev/urandom of="$key" bs=512 count=8 status=none)
  chmod 400 "$key"
fi

# Keep systemd from (re)mounting anything while we work.
systemctl stop "$(unit "$pool" automount)" "$(unit "$pool" mount)" 2>/dev/null || true
for name in "$@"; do
  mp="/home/alex/shared/$name"
  systemctl stop "$(unit "$mp" automount)" "$(unit "$mp" mount)" 2>/dev/null || true
  systemctl stop "systemd-cryptsetup@$name.service" 2>/dev/null || true
  [[ -e "/dev/mapper/$name" ]] && cryptsetup close "$name"
  if findmnt -rn -S "${devs[$name]}" >/dev/null; then
    echo "$name is still mounted:" >&2
    findmnt -S "${devs[$name]}" >&2
    exit 1
  fi
done

for name in "$@"; do
  dev="${devs[$name]}"
  echo
  echo "=== $name ($dev)"
  wipefs -a "$dev"
  cryptsetup luksFormat --batch-mode --type luks2 --label "$name-crypt" \
    --key-file "$key" "$dev"
  cryptsetup open --key-file "$key" "$dev" "$name"
  if [[ "$name" == parity ]]; then
    # One huge parity file: no reserved blocks, few inodes.
    mkfs.ext4 -L "$name" -m 0 -T largefile4 "/dev/mapper/$name"
  else
    mkfs.btrfs -f -L "$name" "/dev/mapper/$name"
  fi
  cryptsetup close "$name"

  read -rp "Add a backup passphrase to $name's keyslot 1 (recommended)? [y/N] " answer
  if [[ "$answer" == [yY]* ]]; then
    cryptsetup luksAddKey --key-file "$key" "$dev"
  fi
done

udevadm settle
for name in "$@"; do
  # udev started systemd-cryptsetup@ when the new LUKS header appeared, while
  # we still had the volume open, so it's "active" without a mapping. Restart
  # it to actually unlock the disk.
  systemctl restart "systemd-cryptsetup@$name.service"
  systemctl start "$(unit "/home/alex/shared/$name" automount)" || true
done
systemctl start "$(unit "$pool" automount)" || true
echo
echo "Done. Make sure configs/backup-disks.nix is switched in, then fill the disks and"
echo "run 'sudo snapraid sync'."
