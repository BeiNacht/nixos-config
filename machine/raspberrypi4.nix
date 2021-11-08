{ config, pkgs, lib, ... }:
{
  imports =
    [
      # <nixos-hardware/common/cpu/intel>
      /etc/nixos/hardware-configuration.nix
      #../configs/docker.nix
      ../configs/common.nix
      ../configs/user.nix
    ];

  # Boot
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;

  # Kernel configuration
  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.kernelParams = [ "cma=64M" "console=tty0" ];

  # Enable additional firmware (such as Wi-Fi drivers).
  hardware.enableRedistributableFirmware = true;

  # # Filesystems
  # fileSystems = {
  #     # There is no U-Boot on the Pi 4 (yet) -- the firmware partition has to be mounted as /boot.
  #     "/boot" = {
  #         device = "/dev/disk/by-label/FIRMWARE";
  #         fsType = "vfat";
  #     };
  #     "/" = {
  #         device = "/dev/disk/by-label/NIXOS_SD";
  #         fsType = "ext4";
  #     };
  # };

  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  networking.hostName = "raspberrypi4";

  # Packages
  environment.systemPackages = with pkgs; [
    nano
    git
    htop
  ];

  # Miscellaneous
  time.timeZone = "Europe/Berlin"; # you probably want to change this -- otherwise, ciao!

  # WARNING: if you remove this, then you need to assign a password to your user, otherwise
  # `sudo` won't work. You can do that either by using `passwd` after the first rebuild or
  # by setting an hashed password in the `users.users.yourName` block as `initialHashedPassword`.
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "21.05";
}
