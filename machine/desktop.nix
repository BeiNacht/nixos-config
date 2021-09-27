{ config, pkgs, lib, ... }:

let
  secrets = import ../configs/secrets.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../configs/gui.nix
      ../configs/docker.nix
      ../configs/libvirt.nix
      ../configs/common.nix
      ../configs/user-gui-applications.nix
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

  boot = {
    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
        gfxmodeEfi = "1024x768";
      };

      efi.canTouchEfiVariables = true;
    };

    initrd.kernelModules = [ "amdgpu" ];
    plymouth.enable = true;
    extraModulePackages = with pkgs.linuxPackages; [ it87 ];
    kernelModules = [ "it87" "v4l2loopback" ];
  };

  networking = {
    hostName = "desktop"; # Define your hostname.
    useDHCP = false;
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.2/24" ];
        privateKey = secrets.wireguard-desktop-private;

        peers = [
          {
            publicKey = secrets.wireguard-vps-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.0/24" ];
            endpoint = "szczepan.ski:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  time.timeZone = "Europe/Berlin";

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
        DEVPATH=hwmon3=devices/platform/it87.656
        DEVNAME=hwmon3=it8665
        FCTEMPS=hwmon3/pwm3=hwmon3/temp1_input hwmon3/pwm2=hwmon3/temp1_input hwmon3/pwm1=hwmon3/temp1_input
        FCFANS=hwmon3/pwm3=hwmon3/fan2_input hwmon3/pwm2=hwmon3/fan1_input hwmon3/pwm1=
        MINTEMP=hwmon3/pwm3=60 hwmon3/pwm2=60 hwmon3/pwm1=60
        MAXTEMP=hwmon3/pwm3=75 hwmon3/pwm2=75 hwmon3/pwm1=75
        MINSTART=hwmon3/pwm3=51 hwmon3/pwm2=51 hwmon3/pwm1=51
        MINSTOP=hwmon3/pwm3=51 hwmon3/pwm2=51 hwmon3/pwm1=51
        MINPWM=hwmon3/pwm1=51 hwmon3/pwm2=51 hwmon3/pwm3=51
        MAXPWM=hwmon3/pwm3=127 hwmon3/pwm2=204
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

  sound.enable = true;

  services = {
    printing.enable = true;
    xserver.videoDrivers = [ "amdgpu" ];
    hardware.xow.enable = true;
    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2" ;
        passphrase = secrets.borg-desktop-key;
      };
      extraCreateArgs = "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = "ssh://szczepan.ski/~/borg-backup/desktop";
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) [
        ".config/chromium/Default/Service Worker/CacheStorage"
        ".cache"
        ".local/share/libvirt/images"
        ".local/share/Steam/steamapps"
        "Games/guild-wars/drive_c/Program Files/Guild Wars/Gw.dat"
        "Games/guild-wars-second/drive_c/Program Files/Guild Wars/Gw.dat"
        "Kamera"
        "Nextcloud"
        "Sync"
        "Workspace"
      ];
    };
  };

  system.stateVersion = "21.05";
}
