{
  fileSystems = {
    "/" = {
      device = "/dev/mapper/lvm-root";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/home" = {
      device = "/dev/mapper/lvm-root";
      fsType = "btrfs";
      options = [
        "subvol=home"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/nix" = {
      device = "/dev/mapper/lvm-root";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/persist" = {
      device = "/dev/mapper/lvm-root";
      fsType = "btrfs";
      options = [
        "subvol=persist"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/mapper/lvm-root";
      fsType = "btrfs";
      options = [
        "subvol=log"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };

  swapDevices = [{device = "/dev/mapper/lvm-swap";}];
}
