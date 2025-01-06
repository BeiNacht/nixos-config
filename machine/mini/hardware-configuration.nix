{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod"];
      kernelModules = ["dm-snapshot"];
    };

    kernelModules = ["kvm-intel"];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
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
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
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
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
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
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
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
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
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
      device = "/dev/disk/by-uuid/7222-8C3F";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };

    "/mnt/disk1" = {
      device = "/dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };

    "/mnt/disk2" = {
      device = "/dev/disk/by-uuid/98a75e01-fa80-469e-820c-1e1e275937b8";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };

    "/mnt/disk3" = {
      device = "/dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };

    "/mnt/parity" = {
      device = "/dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/e59a0c55-7859-40ad-bf55-345708a67816";}
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
