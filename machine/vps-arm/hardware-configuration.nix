{
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd = {
    availableKernelModules = ["xhci_pci" "virtio_scsi" "sr_mod"];
    kernelModules = ["dm-snapshot"];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=root"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=home"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=nix"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=persist"];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=log"];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/DE94-E9C1";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };
  swapDevices = [
    {device = "/dev/disk/by-uuid/3c63b075-76ca-403f-bf75-53269b6bf4fa";}
  ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
