{
  config,
  pkgs,
  lib,
  outputs,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    ../configs/borg.nix
    ../configs/browser.nix
    ../configs/common-linux.nix
    ../configs/develop.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    ../configs/games.nix
    ../configs/hardware.nix
    # ../configs/libvirtd.nix
    ../configs/plasma-desktop.nix
    ../configs/samba.nix
    ../configs/user-gui.nix
    ../configs/user.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  sops = {
    secrets = {
      borg-key = {
        sopsFile = ../secrets/secrets-framework.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  # fileSystems = {
  #   "/home/alex/shared/storage" = {
  #     device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
  #     fsType = "btrfs";
  #     options = [
  #       "autodefrag"
  #       "compress=zstd"
  #       "nodiratime"
  #       "noatime"
  #     ];
  #   };
  # };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/9f90bae0-287b-480c-9aa1-de108b4b4626";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

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
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with pkgs.linuxPackages_latest; [cpupower];

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];

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

  hardware = {
    fw-fanctrl = {
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
                speed = 20;
              }
              {
                temp = 70;
                speed = 25;
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

    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    # openrazer = {
    #   enable = true;
    #   users = ["alex"];
    # };
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        vpl-gpu-rt
      ];
    };
  };

  services = {
    colord.enable = true;
    fprintd.enable = false;

    # btrfs.autoScrub = {
    #   enable = true;
    #   interval = "monthly";
    #   fileSystems = ["/home/alex/shared/storage"];
    # };

    borgbackup.jobs.all = rec {
      repo = "ssh://alex@mini.meteor-altered.ts.net/./homeserver/storage/samba/framework/borg";
    };

    samba.settings.shares = {
      browseable = "yes";
      "guest ok" = "no";
      path = "/home/alex/shared/storage";
      "read only" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
    };

    snapraid = {
      enable = true;
      dataDisks = {
        d1 = "/run/media/alex/disk1/";
        d2 = "/run/media/alex/disk2/";
        d3 = "/run/media/alex/disk3/";
      };
      exclude = [
        "*.unrecoverable"
        "/tmp/"
        "/lost+found/"
      ];
      parityFiles = [
        "/run/media/alex/parity/snapraid.parity"
      ];
      contentFiles = [
        "/run/media/alex/disk1/.snapraid.content"
        "/run/media/alex/disk2/.snapraid.content"
        "/run/media/alex/disk3/.snapraid.content"
        "/home/alex/snapraid.content"
      ];
    };

    throttled = {
      enable = true;
      extraConfig = "
        [GENERAL]
        # Enable or disable the script execution
        Enabled: True
        # SYSFS path for checking if the system is running on AC power
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        # Auto reload config on changes
        Autoreload: True

        ## Settings to apply while connected to Battery power
        [BATTERY]
        # Update the registers every this many seconds
        Update_Rate_s: 30
        # Max package power for time window #1
        PL1_Tdp_W: 15
        # Time window #1 duration
        PL1_Duration_s: 28
        # Max package power for time window #2
        PL2_Tdp_W: 25
        # Time window #2 duration
        PL2_Duration_S: 0.002
        # Max allowed temperature before throttling
        Trip_Temp_C: 85
        # Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
        cTDP: 0
        # Disable BDPROCHOT (EXPERIMENTAL)
        Disable_BDPROCHOT: False

        ## Settings to apply while connected to AC power
        [AC]
        # Update the registers every this many seconds
        Update_Rate_s: 5
        # Max package power for time window #1
        PL1_Tdp_W: 28
        # Time window #1 duration
        PL1_Duration_s: 28
        # Max package power for time window #2
        PL2_Tdp_W: 44
        # Time window #2 duration
        PL2_Duration_S: 0.002
        # Max allowed temperature before throttling
        Trip_Temp_C: 95
        # Set HWP energy performance hints to 'performance' on high load (EXPERIMENTAL)
        # Uncomment only if you really want to use it
        # HWP_Mode: False
        # Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
        cTDP: 0
        # Disable BDPROCHOT (EXPERIMENTAL)
        Disable_BDPROCHOT: False";
    };
  };

  # systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 40960;

  security.sudo.extraRules = [
    {
      users = ["alex"];
      commands = [
        {
          command = "/run/current-system/sw/bin/gw1-power-profile apply";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/gw1-power-profile restore";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

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

      deskflow

      homebank

      powerstat # for measuring power consumption
      powercap # setting power consumption

      snapraid
      mergerfs
      smartmontools

      # Guild Wars 1 is iGPU-bound on this laptop, not CPU-bound. While it
      # runs, cap CPU cores hard (they only need ~6.5W here) and trim the
      # overall package power ceiling below throttled's normal AC caps
      # (28W/44W), so the package stays further from TjMax without starving
      # the iGPU of power. throttled.service is paused so its own PL1/PL2
      # loop doesn't fight this.
      (writeShellApplication {
        name = "gw1-power-profile";
        runtimeInputs = [systemd];
        text = ''
          PKG=/sys/class/powercap/intel-rapl:0
          CORE=/sys/class/powercap/intel-rapl:0:0

          case "''${1:-}" in
            apply)
              systemctl stop throttled.service
              echo 15000000 > "$PKG/constraint_0_power_limit_uw"  # PL1 sustained -> 22W
              echo 25000000 > "$PKG/constraint_1_power_limit_uw"  # PL2 burst -> 36W
              echo 8000000  > "$CORE/constraint_0_power_limit_uw" # cores-only cap -> 4W, rest goes to iGPU (uncore has no cap of its own)
              echo 15000000 > "$CORE/constraint_0_time_window_us"
              ;;
            restore)
              echo 0 > "$CORE/constraint_0_power_limit_uw" # 0 = unset/uncapped on this driver
              systemctl start throttled.service
              ;;
            *)
              echo "usage: gw1-power-profile {apply|restore}" >&2
              exit 1
              ;;
          esac
        '';
      })

      # Launches Guild Wars 1 under the reduced power profile above, and
      # restores throttled's normal caps afterward (even if killed).
      (writeShellApplication {
        name = "gw1";
        text = ''
          sudo gw1-power-profile apply
          trap 'sudo gw1-power-profile restore' EXIT

          env WINEPREFIX="/home/alex/Games/gw/prefix" wine "C:\users\Public\Desktop\Guild Wars.lnk"
        '';
      })
    ];
  };

  # Partition swapfile is on (after LUKS decryption)
  boot.resumeDevice = "/dev/disk/by-uuid/9f90bae0-287b-480c-9aa1-de108b4b4626";

  # Resume Offset is offset of swapfile
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  # boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=190937088" ];
  boot.kernelParams = ["mem_sleep_default=deep"];

  # Suspend-then-hibernate everywhere
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = "suspend-then-hibernate";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "15m";
  };

  systemd = {
    sleep.settings.Sleep = {HibernateDelaySec = "60m";};
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
    };
  };

  system.stateVersion = "24.11";
}
