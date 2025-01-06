{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../configs/filesystem.nix
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/87c6b0fb-b921-47d5-a3a1-4b4c0a4f02ad";
    };

    "/home" = {
      device = "/dev/disk/by-uuid/87c6b0fb-b921-47d5-a3a1-4b4c0a4f02ad";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/87c6b0fb-b921-47d5-a3a1-4b4c0a4f02ad";
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/87c6b0fb-b921-47d5-a3a1-4b4c0a4f02ad";
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/87c6b0fb-b921-47d5-a3a1-4b4c0a4f02ad";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/4339-5A4C";
    };
  };

  swapDevices = [{device = "/dev/disk/by-uuid/831be7b8-5b1b-4bda-a27d-5a1c4efb2c4d";}];

  networking.useDHCP = lib.mkDefault true;
  # nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
