{ config, pkgs, inputs, outputs, ... }:
let
  be = import ../../configs/borg-exclude.nix;
in
{
  nixpkgs = {
    overlays = [ ];
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.sops-nix.nixosModules.sops
    ../../configs/browser.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/games.nix
    ../../configs/develop.nix
    ../../configs/virtualisation.nix
    ../../configs/plasma-wayland.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  # chaotic.mesa-git.enable = true;

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      borg-key = {
        sopsFile = ../../secrets-desktop.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      hashedPassword = {
        neededForUsers = true;
      };
    };
  };

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-znver2" ];

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        configurationLimit = 5;
        useOSProber = true;
      };
      efi = { canTouchEfiVariables = true; };
    };

    kernelPackages = pkgs.linuxPackages_cachyos;
#    extraModulePackages = with pkgs.linuxPackages_cachyos; [ it87 ];
    kernelModules = [ "nct6775" ];
    # kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  };

  # systemd.services = {
  #   monitor = {
  #     description = "AMDGPU Control Daemon";
  #     wantedBy = [ "multi-user.target" ];
  #     after = [ "multi-user.target" ];
  #     serviceConfig = { ExecStart = "${pkgs.lact}/bin/lact daemon"; };
  #   };
  # };

  networking = {
    hostName = "desktop";
    useDHCP = false;
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    lact
    amdgpu_top

    python3
    python311Packages.tkinter

    snapraid
    mergerfs

    gimp

    clinfo

#    fan2go

#    unigine-superposition
  ];

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # fancontrol = {
    #   enable = true;
    #   config = ''
    #     INTERVAL=10
    #     DEVPATH=hwmon3=devices/platform/it87.656
    #     DEVNAME=hwmon3=it8665
    #     FCTEMPS=hwmon3/pwm1=hwmon6/temp1_input hwmon3/pwm2=hwmon6/temp3_input hwmon3/pwm3=hwmon6/temp3_input
    #     FCFANS=hwmon3/pwm1=hwmon3/fan1_input hwmon3/pwm2=hwmon3/fan2_input hwmon3/pwm3=hwmon3/fan3_input
    #     MINTEMP=hwmon3/pwm1=60 hwmon3/pwm2=60 hwmon3/pwm3=60
    #     MAXTEMP=hwmon3/pwm1=80 hwmon3/pwm2=80 hwmon3/pwm3=80
    #     MINSTART=hwmon3/pwm1=51 hwmon3/pwm2=102 hwmon3/pwm3=102
    #     MINSTOP=hwmon3/pwm1=51 hwmon3/pwm2=102 hwmon3/pwm3=102
    #     MINPWM=hwmon3/pwm1=51 hwmon3/pwm2=102 hwmon3/pwm3=102
    #     MAXPWM=hwmon3/pwm1=127 hwmon3/pwm2=127 hwmon3/pwm3=127
    #   '';
    # };

    pulseaudio.enable = false;
  };

  programs = {
    coolercontrol.enable = true;
    corectrl = {
      enable = true;
      # gpuOverclock.ppfeaturemask
      gpuOverclock.enable = true;
    };
  };


  services = {
    power-profiles-daemon.enable = true;
    netdata.enable = true;
    printing.enable = true;
    fwupd.enable = true;

    xserver.videoDrivers = [ "amdgpu" ];

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    samba = {
      enable = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "server";
          "netbios name" = "server";
          security = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          logging = "systemd";
          "max log size" = 50;
          "invalid users" = [
            "root"
          ];
          "passwd program" = "/run/wrappers/bin/passwd %u";
        };
        shares = {
          browseable = "yes";
          "guest ok" = "no";
          path = "/home/alex/shared/storage";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";

        };
      };
    };

    tailscale.enable = true;

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-key.path}";
      };
      extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_ed25519";
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
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  swapDevices = [{
    device = "/swapfile";
    size = 32 * 1024;
  }];

  system.stateVersion = "24.11";
}
