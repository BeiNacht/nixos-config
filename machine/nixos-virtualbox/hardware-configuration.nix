{
  lib,
  modulesPath,
  ...
}: {
  boot.initrd.availableKernelModules = ["ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod"];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/3719ec05-eb90-455f-98c0-0313c0bcb964";
      fsType = "btrfs";
      options = ["subvol=root" "compress=zstd" "noatime"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/3719ec05-eb90-455f-98c0-0313c0bcb964";
      fsType = "btrfs";
      options = ["subvol=home" "compress=zstd" "noatime"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/3719ec05-eb90-455f-98c0-0313c0bcb964";
      fsType = "btrfs";
      options = ["subvol=nix" "compress=zstd" "noatime"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/3719ec05-eb90-455f-98c0-0313c0bcb964";
      fsType = "btrfs";
      options = ["subvol=persist" "compress=zstd" "noatime"];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/3719ec05-eb90-455f-98c0-0313c0bcb964";
      fsType = "btrfs";
      options = ["subvol=log" "compress=zstd" "noatime"];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/6F47-35E9";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true;

  # nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;
}
