{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  fileSystems = {
    # "/" = {
    #   device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    #   fsType = "btrfs";
    #   options = [
    #     "subvol=root"
    #     "discard=async"
    #     "compress=zstd"
    #     "nodiratime"
    #     "noatime"
    #   ];
    # };
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=16G" "mode=755"];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
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
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
      ];
    };
    "/var/log" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
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
    "/persist" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
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
    "/boot" = {
      device = "/dev/disk/by-uuid/427A-97BA";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
    "/home/alex/shared/storage" = {
      device = "/dev/disk/by-uuid/58259976-4f63-4f60-a755-7870b08286e7";
      fsType = "btrfs";
      options = [
        "subvol=@data"
        "discard=async"
        "compress=zstd"
        "nodiratime"
        "noatime"
        "nofail"
        "x-systemd.automount"
      ];
    };
  };

  environment.etc.crypttab.text = ''
    luks-e36ec189-2211-4bcc-bb9d-46650443d76b UUID=e36ec189-2211-4bcc-bb9d-46650443d76b /persist/luks-key01
  '';

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/9f90bae0-287b-480c-9aa1-de108b4b4626";
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
