{ config, pkgs, lib, ... }:

let
  secrets = import ../configs/secrets.nix;
  secrets-wireguard = import ../configs/secrets-wireguard-publickeys.nix;
  secrets-desktop = import ../configs/secrets-desktop.nix;
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
        privateKey = secrets-desktop.wireguard-desktop-private;

        peers = [
          {
            publicKey = secrets-wireguard.wireguard-vps-public;
            presharedKey = secrets-wireguard.wireguard-preshared;
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
        # amdvlk
      ];
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

    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  sound.enable = true;

  services = {
    printing.enable = true;
    xserver.videoDrivers = [ "amdgpu" ];
    hardware.xow.enable = true;
    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2" ;
        passphrase = secrets-desktop.borg-desktop-key;
      };
      extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = "ssh://u278697-sub2@u278697.your-storagebox.de:23/./borg";
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) [
        ".cache"
        ".config/chromium/Default/Service Worker/CacheStorage"
        ".config/discord/Cache"
        ".local/share/libvirt/images"
        ".local/share/Steam/config/htmlcache/Cache"
        ".local/share/Steam/steamapps"
        ".local/share/Trash"
        "Games/guild-wars-second/drive_c/Program Files/Guild Wars/Gw.dat"
        "Games/guild-wars/drive_c/Program Files/Guild Wars/Gw.dat"
        "Kamera"
        "Nextcloud"
        "shared"
        "Sync"
        "Workspace"
      ];
    };
  };

  system.stateVersion = "21.05";
}
