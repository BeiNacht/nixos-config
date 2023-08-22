{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> {};
  secrets = import ../configs/secrets.nix;
  wireguard = import ../configs/wireguard.nix;
in
{
  imports = [
    <nixos-hardware/framework/12th-gen-intel>
    <home-manager/nixos>
    /etc/nixos/hardware-configuration.nix
    ../configs/gui.nix
    ../configs/docker.nix
    ../configs/libvirt.nix
    ../configs/common.nix
    ../configs/games.nix
    ../configs/browser.nix
    ../configs/user.nix
    ../configs/user-gui.nix
    ../configs/gnome.nix
    /home/alex/Workspace/fw-fanctrl-nix/service.nix
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

  # nixpkgs.localSystem = {
  #   gcc.arch = "alderlake";
  #   gcc.tune = "alderlake";
  #   system = "x86_64-linux";
  # };

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-alderlake" ];
  #  programs.nix-ld.enable = true;

  networking = {
    hostName = "framework";
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.7/24" ];
        privateKey = secrets.wireguard-framework-private;

        peers = [{
          publicKey = wireguard.wireguard-vps-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "szczepan.ski:51820";
          persistentKeepalive = 25;
        }];
      };
    };
  };

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
    pulseaudio.enable = false;
  };

  # Bring in some audio
  security.rtkit.enable = true;
  # rtkit is optional but recommended
  services = {
    power-profiles-daemon.enable = true;
    fw-fanctrl.enable = true;
    thermald.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  programs.kdeconnect.enable = true;
  environment.systemPackages =
    with unstable.pkgs; [
      cinnamon.warpinator
      psensor
      gnumake
      pkg-config
      libftdi
      libusb1
      gcc
      # coreboot-toolchain.arm
      intel-gpu-tools
      msr-tools
      (import ("/home/alex/Workspace/fw-ectool/default.nix"))
    ];

  # Set up deep sleep + hibernation
  swapDevices = [
    { device = "/swapfile"; }
  ];

  # Partition swapfile is on (after LUKS decryption)
  boot.resumeDevice = "/dev/disk/by-uuid/ab1126e8-ae5a-4313-a520-4dc267fea528";

  # Resume Offset is offset of swapfile
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=128563200" ];

  # Suspend-then-hibernate everywhere
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=2m
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=60m";

  system.stateVersion = "23.05";
}
