{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../configs/gui.nix
      ../configs/docker.nix
      ../configs/libvirt.nix
      ../configs/common.nix
      ../configs/user-gui.nix
      ../configs/user.nix
    ];

  # Use the systemd-boot EFI boot loader.
  fileSystems."/".options = [ "noatime" "discard" ];
  fileSystems."/boot".options = [ "noatime" "discard" ];
  fileSystems."/mnt/second" = {
    device = "/dev/disk/by-uuid/49c04c91-752d-4dff-b4d9-40a0b9a7bf7c";
    fsType = "ext4";
    options = [ "noatime" "discard" ];
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.gfxmodeEfi = "1024x768";
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.plymouth.enable = true;
  boot.extraModulePackages = with pkgs.linuxPackages; [ it87 ];
  boot.kernelModules = [ "it87" ];

  networking.hostName = "desktop"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  console = {
     font = "latarcyrheb-sun32";
     keyMap = "us";
  };

  hardware = {
    cpu.amd.updateMicrocode = true;

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
        amdvlk
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };

    fancontrol = {
      enable = true;
      config = ''
        INTERVAL=10
        DEVPATH=hwmon2=devices/platform/it87.656
        DEVNAME=hwmon2=it8665
        FCTEMPS=hwmon2/pwm3=hwmon2/temp1_input hwmon2/pwm2=hwmon2/temp1_input hwmon2/pwm1=hwmon2/temp1_input
        FCFANS=hwmon2/pwm3=hwmon2/fan2_input hwmon2/pwm2=hwmon2/fan1_input hwmon2/pwm1=
        MINTEMP=hwmon2/pwm3=60 hwmon2/pwm2=60 hwmon2/pwm1=60
        MAXTEMP=hwmon2/pwm3=75 hwmon2/pwm2=75 hwmon2/pwm1=75
        MINSTART=hwmon2/pwm3=51 hwmon2/pwm2=51 hwmon2/pwm1=51
        MINSTOP=hwmon2/pwm3=51 hwmon2/pwm2=51 hwmon2/pwm1=51
        MINPWM=hwmon2/pwm1=51 hwmon2/pwm2=51 hwmon2/pwm3=51
        MAXPWM=hwmon2/pwm3=127 hwmon2/pwm2=204
      '';
    };

    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  environment.systemPackages = with pkgs; [
    cpu-x
    hwinfo
    hardinfo
    phoronix-test-suite
    fswatch
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];
  services.hardware.xow.enable = true;
  services.printing.enable = true;
  sound.enable = true;

  system.stateVersion = "21.05";
}
