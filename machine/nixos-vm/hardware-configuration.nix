{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "sr_mod"];
      kernelModules = ["dm-snapshot"];
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/45ecad42-0026-4ba1-a4d5-a273878cd587";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/45ecad42-0026-4ba1-a4d5-a273878cd587";
      fsType = "btrfs";
      options = [
        "subvol=home"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/45ecad42-0026-4ba1-a4d5-a273878cd587";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/45ecad42-0026-4ba1-a4d5-a273878cd587";
      fsType = "btrfs";
      options = [
        "subvol=persist"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/45ecad42-0026-4ba1-a4d5-a273878cd587";
      fsType = "btrfs";
      options = [
        "subvol=log"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/1023-617C";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/1b23dce3-e85e-4d83-be57-388a3d6e36e2";}
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  # hardware.parallels.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["prl-tools"];
}
