#!/usr/bin/env bash
# Encrypt one disk of the desktop's ext4 SnapRAID backup set in place (LUKS2),
# keeping its data:
#
#   sudo ./scripts/encrypt-backup-disk.sh <disk1|disk2|disk3|parity>
#
# Steps: SMART check -> unmount -> fsck -> shrink ext4 by 64 MiB -> cryptsetup
# reencrypt --encrypt (LUKS2, label <disk>-crypt, key /persist/backup-hdd.key)
# -> open -> fsck -> grow ext4 back -> close. Re-running it resumes an
# interrupted encryption and/or finishes the remaining steps.
#
# Afterwards add the disk to encryptedBackupDisks in machine/desktop.nix and
# switch. Run `snapraid sync` before starting so parity is current.
set -euo pipefail

key=/persist/backup-hdd.key
pool=/home/alex/shared/backup

declare -A uuids=(
  [disk1]=3c4b5d00-43c0-48be-81b8-c2b3977e015b
  [disk2]=98a75e01-fa80-469e-820c-1e1e275937b8
  [disk3]=0301db98-264f-4b18-9423-15691063f73d
  [parity]=6cce037c-d2d4-4940-bb69-6d2b84fd41aa
)

name="${1:-}"
if [[ -z "$name" || -z "${uuids[$name]:-}" ]]; then
  echo "usage: $0 <disk1|disk2|disk3|parity>" >&2
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

mp="/home/alex/shared/$name"
mapper="/dev/mapper/$name"
unit() { systemd-escape --path --suffix="$2" "$1"; }

# Resolve the partition: by LUKS label once encryption has started, else by
# the ext4 UUID (only while it's still a plain partition, not the dm device).
if [[ -e "/dev/disk/by-label/$name-crypt" ]]; then
  dev="$(readlink -f "/dev/disk/by-label/$name-crypt")"
elif [[ -e "/dev/disk/by-uuid/${uuids[$name]}" ]]; then
  dev="$(readlink -f "/dev/disk/by-uuid/${uuids[$name]}")"
  if [[ "$dev" == /dev/dm-* ]]; then
    echo "$name resolves to $dev (already an opened LUKS mapping?) - check lsblk" >&2
    exit 1
  fi
else
  echo "$name not found - is it plugged in?" >&2
  exit 1
fi
disk="/dev/$(lsblk -no PKNAME "$dev" | head -n1)"
echo "$name: partition $dev on $disk"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL,SERIAL "$disk"
echo

# Keep systemd from remounting it (or the pool on top) while we work.
stop_mounts() {
  systemctl stop "$(unit "$pool" automount)" "$(unit "$pool" mount)" 2>/dev/null || true
  systemctl stop "$(unit "$mp" automount)" "$(unit "$mp" mount)" 2>/dev/null || true
  if findmnt -rn -S "$dev" >/dev/null || { [[ -e "$mapper" ]] && findmnt -rn -S "$mapper" >/dev/null; }; then
    echo "$name is still mounted somewhere:" >&2
    findmnt -S "$dev" >&2 || findmnt -S "$mapper" >&2
    exit 1
  fi
}
restore_mounts() {
  systemctl start "$(unit "$mp" automount)" "$(unit "$pool" automount)" || true
}

# fsck with automatic safe repairs; stop on anything that needs a human.
check_fs() {
  local rc=0
  e2fsck -f -p "$1" || rc=$?
  if ((rc >= 4)); then
    echo "e2fsck found errors on $1 it won't fix automatically (exit $rc)." >&2
    echo "Inspect with: sudo e2fsck -f $1   (and check SMART) - aborting." >&2
    exit 1
  fi
}

reencrypt_pending() { cryptsetup luksDump "$dev" 2>/dev/null | grep -q 'online-reencrypt'; }

if cryptsetup isLuks "$dev"; then
  stop_mounts
  if reencrypt_pending; then
    echo "Resuming interrupted encryption of $dev"
    cryptsetup reencrypt --resume-only --key-file "$key" "$dev"
  else
    echo "$dev is already LUKS - finishing remaining steps"
  fi
else
  [[ "$(blkid -s TYPE -o value "$dev")" == ext4 ]] || {
    echo "$dev is not ext4 - refusing" >&2
    exit 1
  }
  [[ "$(blkid -s LABEL -o value "$dev")" == "$name" ]] || {
    echo "$dev label isn't '$name' - refusing" >&2
    exit 1
  }

  if command -v smartctl >/dev/null; then
    if ! smartctl -H "$disk"; then
      echo "SMART health check failed or couldn't run on $disk - aborting." >&2
      echo "(USB bridge? try: smartctl -d sat -H $disk)" >&2
      exit 1
    fi
  else
    echo "smartctl not installed - skipping SMART check (nix shell nixpkgs#smartmontools)"
  fi

  echo
  echo "This will encrypt $dev ($name) in place. It rewrites the whole disk and"
  echo "takes many hours. Have you run 'snapraid sync' and is the disk healthy?"
  read -rp "Type '$name' to continue: " answer
  [[ "$answer" == "$name" ]] || exit 1

  if [[ ! -e "$key" ]]; then
    echo "Creating $key"
    (umask 077 && dd if=/dev/urandom of="$key" bs=512 count=8 status=none)
    chmod 400 "$key"
  fi

  stop_mounts
  check_fs "$dev"

  # Make room for the LUKS2 header: shrink the fs to the partition minus 64 MiB
  # (cryptsetup needs 32 MiB; the rest is slack, given back by the grow below).
  bs="$(tune2fs -l "$dev" | awk -F: '/^Block size/ {gsub(/ /,"",$2); print $2}')"
  blocks="$(tune2fs -l "$dev" | awk -F: '/^Block count/ {gsub(/ /,"",$2); print $2}')"
  part_bytes="$(blockdev --getsize64 "$dev")"
  target_kib=$(((part_bytes - 64 * 1024 * 1024) / 1024))
  if ((blocks * bs / 1024 > target_kib)); then
    echo "Shrinking ext4 on $dev to ${target_kib}K"
    resize2fs "$dev" "${target_kib}K"
  fi

  echo "Encrypting $dev - safe to interrupt; re-run this script to resume."
  cryptsetup reencrypt --encrypt --type luks2 --reduce-device-size 32M \
    --label "$name-crypt" --key-file "$key" "$dev"
fi

reencrypt_pending && {
  echo "Encryption still incomplete on $dev - re-run to resume" >&2
  exit 1
}

[[ -e "$mapper" ]] || cryptsetup open --key-file "$key" "$dev" "$name"
check_fs "$mapper"
resize2fs "$mapper" # grow back to fill the LUKS device
cryptsetup close "$name"

if ! cryptsetup luksDump "$dev" | grep -qE '^ +1: luks2'; then
  read -rp "Add a backup passphrase to keyslot 1 (recommended)? [y/N] " answer
  if [[ "$answer" == [yY]* ]]; then
    cryptsetup luksAddKey --key-file "$key" "$dev"
  fi
fi

restore_mounts
echo
echo "$name is encrypted. Add \"$name\" to encryptedBackupDisks in machine/desktop.nix"
echo "and run: sudo nixos-rebuild switch --flake .#desktop"
