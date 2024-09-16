{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d43faf8e-ec90-4735-a1a4-aff6897604b2";
    options = [ "discard" ];
    fsType = "ext4";
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/441a7d92-c3eb-4867-81c7-4e1dc3a1c54d";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-ba8eb308-e85f-4cee-9993-88c5ba0966ea" = {
    device = "/dev/disk/by-uuid/ba8eb308-e85f-4cee-9993-88c5ba0966ea";
    allowDiscards = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1838-7DA8";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
