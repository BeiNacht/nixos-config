# Hot-swappable SnapRAID backup set (USB): LUKS2 disk1-3 + parity (label
# <disk>-crypt, key /persist/backup-hdd.key), formatted with
# scripts/format-backup-disks.sh: btrfs data disks pooled by mergerfs at
# /home/alex/shared/backup, ext4 parity. Plugging a disk in unlocks it via
# udev; the first access to a mount point mounts it via automount. None is
# required for boot (nofail). Use `sudo storage-hotswap eject backup` before
# pulling them.
#
# The set can move between hosts that import this module, as long as each has
# a copy of /persist/backup-hdd.key. SnapRAID state lives on the data disks
# (.snapraid.content), so `snapraid sync` works from whichever host has them.
{
  config,
  lib,
  pkgs,
  ...
}: let
  backupDataDisks = ["disk1" "disk2" "disk3"];
  backupDisks = backupDataDisks ++ ["parity"];
  key = "/persist/backup-hdd.key";
  mountpoint = d: "/home/alex/shared/${d}";

  hotswapOptions = [
    "noatime"
    "noauto" # Don't mount at boot
    "x-systemd.automount" # Mount on first access
    "x-systemd.idle-timeout=10min" # Unmount after 10 mins of silence
    "x-systemd.device-timeout=10s" # Fail fast if the drive isn't plugged in
    "nofail" # Boot proceeds normally if the drive is missing
  ];
  hotswapBackup = d: {
    device = "/dev/mapper/${d}"; # pulls in systemd-cryptsetup@<d>.service
    fsType =
      if d == "parity"
      then "ext4"
      else "btrfs";
    # No compression: SnapRAID sizes parity by uncompressed file size.
    options = lib.optional (d != "parity") "nodiratime" ++ hotswapOptions;
  };
in {
  fileSystems =
    lib.genAttrs' backupDisks (d: lib.nameValuePair (mountpoint d) (hotswapBackup d))
    // {
      # mergerfs pool over disk1-3. Accessing it mounts all three data disks
      # first (requires-mounts-for); if one is missing the pool fails to mount.
      ${mountpoint "backup"} = {
        device = lib.concatMapStringsSep ":" mountpoint backupDataDisks;
        fsType = "fuse.mergerfs";
        options =
          [
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=10min"
            "nofail"
            "fsname=backup"
            "allow_other"
            "cache.files=off"
            "category.create=mfs" # new files go to the disk with the most free space
            "moveonenospc=true"
            "minfreespace=100G"
            "dropcacheonclose=true"
          ]
          ++ map (d: "x-systemd.requires-mounts-for=${mountpoint d}") backupDataDisks;
      };
    };
  system.fsPackages = [pkgs.mergerfs];

  environment.etc.crypttab.text =
    lib.concatMapStrings (d: "${d} LABEL=${d}-crypt ${key} nofail,x-systemd.device-timeout=10s\n") backupDisks;

  # Unlock hot-plugged backup disks as soon as they appear.
  services.udev.extraRules =
    lib.concatMapStrings (d: ''SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="crypto_LUKS", ENV{ID_FS_LABEL}=="${d}-crypt", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@${d}.service"'' + "\n") backupDisks;

  services.snapraid = {
    enable = true;
    dataDisks = lib.genAttrs backupDataDisks (d: "${mountpoint d}/");
    parityFiles = ["${mountpoint "parity"}/snapraid.parity"];
    contentFiles = map (d: "${mountpoint d}/.snapraid.content") backupDataDisks;
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
    ];
    # Save the content files every 100 GB processed, so an interrupted sync
    # resumes from there instead of starting over.
    extraConfig = "autosave 100";
  };

  systemd.services = let
    inherit (config.services) snapraid;
    stateDirs = lib.unique (map dirOf (snapraid.parityFiles ++ snapraid.contentFiles));
    # snapraid redraws its progress line with \r, which the journal stores as
    # one unreadable "[48K blob data]" entry at a time. Split on \r and keep one
    # progress line per minute, so `journalctl -fu snapraid-sync` is readable.
    # snapraid stays the main process (exec), so with KillMode=mixed a stop
    # signals only snapraid and gawk keeps logging while it saves its state.
    # gawk ignores SIGTERM so it isn't killed with output still unflushed; it
    # exits on EOF once snapraid does.
    snapraidLogged = pkgs.writeShellScript "snapraid-logged" ''
      exec ${pkgs.snapraid}/bin/snapraid "$@" > >(trap "" TERM; exec ${pkgs.gawk}/bin/gawk -v RS='[\r\n]' '
        /^[0-9]+%, / { if (systime() - last < 60) next; last = systime() }
        NF { print; fflush() }')
    '';
    # Manual-only: no timers, and make sure every disk is mounted first.
    manual = {
      startAt = lib.mkForce [];
      unitConfig.RequiresMountsFor = map mountpoint backupDisks;
      serviceConfig = {
        KillMode = "mixed";
        # On stop, snapraid saves the content files before exiting, which can
        # take minutes on the USB disks: don't SIGKILL it halfway through.
        TimeoutStopSec = "15min";
      };
    };
  in {
    snapraid-sync = lib.recursiveUpdate manual {
      serviceConfig = {
        ExecStart = lib.mkForce "${snapraidLogged} sync";
        User = "alex";
        Group = "users";
        # Freshly formatted disks (and state left by an earlier root sync) are
        # root-owned: hand the parity/content dirs and files to alex first.
        # (Upstream's `snapraid touch` pre-step, if enabled, runs after it.)
        ExecStartPre = lib.mkForce ([
            "+${pkgs.writeShellScript "snapraid-sync-chown" ''
              for f in ${lib.escapeShellArgs (stateDirs ++ snapraid.parityFiles ++ snapraid.contentFiles)}; do
                if [ -e "$f" ]; then ${pkgs.coreutils}/bin/chown alex:users "$f"; fi
              done
            ''}"
          ]
          ++ lib.optional snapraid.touchBeforeSync "${pkgs.snapraid}/bin/snapraid touch");
        # Upstream lists the parity *file* in ReadWritePaths, so the unit fails
        # at namespace setup until a first sync has created it. Allow its
        # directory instead (plus the data disks, as upstream).
        ReadWritePaths = lib.mkForce (lib.unique (lib.attrValues snapraid.dataDisks ++ stateDirs));
      };
    };
    snapraid-scrub = lib.recursiveUpdate manual {
      serviceConfig.ExecStart = lib.mkForce "${snapraidLogged} scrub -p ${toString snapraid.scrub.plan} -o ${toString snapraid.scrub.olderThan}";
    };
  };

  environment.systemPackages = with pkgs; [
    snapraid
    smartmontools
    mergerfs

    (writeShellApplication {
      name = "storage-hotswap";
      runtimeInputs = [coreutils util-linux systemd cryptsetup];
      text = builtins.readFile ../home/bin/storage-hotswap;
    })
  ];
}
