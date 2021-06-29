{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../../configs/gui.nix
      ../../configs/virtualisation.nix
      ../../configs/common.nix
      ../../configs/user.nix
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
  networking.interfaces.enp8s0.useDHCP = true;
  networking.interfaces.wlp6s0.useDHCP = true;

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
    elementary-xfce-icon-theme
    gnomeExtensions.appindicator
  ];

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.desktopManager.pantheon.enable = true;
  # services.xserver.desktopManager.pantheon.extraWingpanelIndicators = [ pkgs.pantheon.wingpanel-indicator-nightlight ];
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.hardware.xow.enable = true;

  # fonts.fonts = with pkgs; [
  #   open-sans
  #   roboto-mono
  #   noto-fonts
  #   noto-fonts-cjk
  #   noto-fonts-emoji
  #   liberation_ttf
  #   fira-code
  #   fira-code-symbols
  #   mplus-outline-fonts
  #   dina-font
  #   proggyfonts
  # ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "cp"
        "common-aliases"
        "docker "
        "systemd"
        "wd"
        "kubectl"
        "git"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
