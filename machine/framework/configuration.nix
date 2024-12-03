{
  config,
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}: let
  be = import ../../configs/borg-exclude.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../configs/browser.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/games.nix
    ../../configs/virtualization.nix
    ../../configs/plasma.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets-framework.yaml;

    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-alderlake"
  ];

  # nixpkgs.localSystem = {
  #   gcc.arch = "alderlake";
  #   gcc.tune = "alderlake";
  #   system = "x86_64-linux";
  # };

  boot = {
    tmp.useTmpfs = false;
    kernelPackages = pkgs.linuxPackages_6_11;

    initrd = {
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/eddab069-d369-4b26-8b4e-f3b907ba6f6c";
          allowDiscards = true;
          preLVM = true;
        };
      };
    };
  };

  networking = {
    hostName = "framework";
  };

  time.timeZone = "Europe/Berlin";

  programs.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
      strategies = {
        "lazy" = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 15;
            }
            {
              temp = 50;
              speed = 15;
            }
            {
              temp = 65;
              speed = 25;
            }
            {
              temp = 70;
              speed = 35;
            }
            {
              temp = 75;
              speed = 50;
            }
            {
              temp = 85;
              speed = 100;
            }
          ];
        };
      };
    };
  };

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    openrazer = {
      enable = true;
      users = ["alex"];
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        vpl-gpu-rt
      ];
    };
    pulseaudio.enable = false;
  };

  # Bring in some audio
  security.rtkit.enable = true;
  # rtkit is optional but recommended
  services = {
    power-profiles-daemon.enable = true;
    colord.enable = true;
    fprintd.enable = false;

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/home/alex/shared/storage"];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    borgbackup.jobs.home = rec {
      repo = "ssh://u278697-sub9@u278697.your-storagebox.de:23/./borg";

      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-key.path}";
      };
      extraCreateArgs = "--stats --verbose --checkpoint-interval=600 --exclude-caches";
      extraPruneArgs = [
        "--save-space"
        "--stats"
      ];
      extraCompactArgs = [
        "--cleanup-commits"
      ];
      environment = {
        BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_ed25519";
        BORG_BASE_DIR = "/persist/borg";
      };
      readWritePaths = ["/persist/borg"];
      paths = ["/home/alex" "/persist"];
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      exclude = map (x: "/home/alex/" + x) be.borg-exclude;
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 40960;

  environment = {
    sessionVariables = {LIBVA_DRIVER_NAME = "iHD";}; # Force intel-media-driver
    systemPackages = with pkgs; [
      resources
      gnumake
      pkg-config
      libftdi
      libusb1
      gcc

      intel-gpu-tools
      msr-tools
      quota

      mergerfs
      snapraid

      gparted
      homebank
      # fahviewer
      # fahcontrol
    ];
  };

  # Partition swapfile is on (after LUKS decryption)
  boot.resumeDevice = "/dev/disk/by-uuid/9f90bae0-287b-480c-9aa1-de108b4b4626";

  # Resume Offset is offset of swapfile
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  # boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=190937088" ];
  boot.kernelParams = ["mem_sleep_default=deep"];

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

  system.stateVersion = "24.11";
}
