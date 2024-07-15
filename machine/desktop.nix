{ config, pkgs, lib, ... }:

let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  wireguard = import ../configs/wireguard.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../configs/browser.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/games.nix
    ../configs/libvirt.nix
    ../configs/plasma.nix
    ../configs/user-gui.nix
    ../configs/user.nix
  ];

  #  nixpkgs.localSystem = {
  #    gcc.arch = "znver2";
  #    gcc.tune = "znver2";
  #    system = "x86_64-linux";
  #  };

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-znver2" ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = { canTouchEfiVariables = true; };
    };

    # initrd.kernelModules = [ "amdgpu" ];
    plymouth.enable = true;

    extraModulePackages = with pkgs.linuxPackages; [ it87 zenpower ];
    kernelModules = [ "it87" "zenpower" ];
    kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
    supportedFilesystems = [ "ntfs" ];
    blacklistedKernelModules = [ "k10temp" ];
  };

  systemd.services = {
    monitor = {
      description = "AMDGPU Control Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = { ExecStart = "${unstable.pkgs.lact}/bin/lact daemon"; };
    };
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
    # wireguard.interfaces = {
    #   wg0 = {
    #     ips = [ "10.100.0.2/24" ];
    #     privateKey = secrets.wireguard-desktop-private;
    #     peers = [{
    #       publicKey = wireguard.wireguard-vps-public;
    #       presharedKey = secrets.wireguard-preshared;
    #       allowedIPs = [ "10.100.0.0/24" ];
    #       endpoint = "old.szczepan.ski:51820";
    #       persistentKeepalive = 25;
    #     }];
    #   };
    # };
  };

  time.timeZone = "Europe/Berlin";

  console = {
    font = "latarcyrheb-sun32";
    keyMap = "us";
  };

  environment.systemPackages = with unstable.pkgs; [
    unigine-valley
    unigine-superposition
    lact
    amdgpu_top
    python3
    python311Packages.tkinter
  ];

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;
    cpu.amd.updateMicrocode = true;

    bluetooth.enable = true;
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      # extraPackages = with pkgs; [
      #   rocm-opencl-icd
      #   rocm-opencl-runtime
      #   amdvlk
      # ];
      # extraPackages32 = with pkgs; [
      #   driversi686Linux.amdvlk
      # ];
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

    pulseaudio.enable = false;
  };

  sound.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    netdata.enable = true;
    printing.enable = true;
    # xserver.videoDrivers = [ "amdgpu" ];

    displayManager.autoLogin = {
      enable = true;
      user = "alex";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    tailscale.enable = true;

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_ed25519";
      paths = "/home/alex";
      repo = secrets.borg-repo;
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  home-manager.users.alex.services.barrier.client = {
    enable = true;
    enableCrypto = false;
    name = "desktop";
    server = "192.168.0.168:24800";
  };

  system.stateVersion = "24.05";
}
