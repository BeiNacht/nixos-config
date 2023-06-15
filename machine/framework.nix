{ config, pkgs, lib, ... }:
let
in
{
  imports =
    [
      <nixos-hardware/framework/12th-gen-intel>
      /etc/nixos/hardware-configuration.nix
      ../configs/gui.nix
      ../configs/docker.nix
      ../configs/libvirt.nix
      ../configs/common.nix
      ../configs/user.nix
      ../configs/user-gui.nix
      ../configs/user-gui-applications.nix
      ../configs/pantheon.nix
      <home-manager/nixos>
    ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
    plymouth.enable = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };


  networking.hostName = "framework"; # Define your hostname.
  time.timeZone = "Europe/Berlin";

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
  };

  services = {
    power-profiles-daemon.enable = true;
    auto-cpufreq.enable = true;

    # # Enable fractional scaling
    # xserver.desktopManager.gnome = {
    #   extraGSettingsOverrides = ''
    #     [org.gnome.mutter]
    #     experimental-features=['scale-monitor-framebuffer']
    #   '';
    #   extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
    # };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # # Set display settings with 150% fractional scaling
  # systemd.tmpfiles.rules = [
  #   "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" ''
  #     <monitors version="2">
  #       <configuration>
  #         <logicalmonitor>
  #           <x>0</x>
  #           <y>0</y>
  #           <scale>1.5009980201721191</scale>
  #           <primary>yes</primary>
  #           <monitor>
  #             <monitorspec>
  #               <connector>eDP-1</connector>
  #               <vendor>BOE</vendor>
  #               <product>0x095f</product>
  #               <serial>0x00000000</serial>
  #             </monitorspec>
  #             <mode>
  #               <width>2256</width>
  #               <height>1504</height>
  #               <rate>59.999</rate>
  #             </mode>
  #           </monitor>
  #         </logicalmonitor>
  #       </configuration>
  #     </monitors>
  #   ''}"
  # ];

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    powertop
  ];

  system.stateVersion = "23.05";
}
