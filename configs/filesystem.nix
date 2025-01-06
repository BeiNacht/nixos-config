{
  fileSystems = {
    "/" = {
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
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };
};