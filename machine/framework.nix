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
    ../configs/filesystem.nix
    ../configs/browser.nix
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/games.nix
    ../configs/develop.nix
    ../configs/hardware.nix
    ../configs/libvirtd.nix
    ../configs/plasma.nix
    ../configs/user-gui.nix
    ../configs/user.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-framework.yaml;

    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    };
    "/home" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    };
    "/var/log" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    };
    "/persist" = {
      device = "/dev/disk/by-uuid/20780bfe-5714-4c2f-bf53-7296b76cfbdc";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/427A-97BA";
    };
    # "/home/alex/shared/storage" = {
    #   device = "/dev/disk/by-uuid/58259976-4f63-4f60-a755-7870b08286e7";
    #   fsType = "btrfs";
    #   options = [
    #     "subvol=@data"
    #     "discard=async"
    #     "compress=zstd"
    #     "nodiratime"
    #     "noatime"
    #     "nofail"
    #     "x-systemd.automount"
    #   ];
    # };
  };

  # environment.etc.crypttab.text = ''
  #   luks-e36ec189-2211-4bcc-bb9d-46650443d76b UUID=e36ec189-2211-4bcc-bb9d-46650443d76b /persist/luks-key01
  # '';

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/9f90bae0-287b-480c-9aa1-de108b4b4626";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    # openrazer = {
    #   enable = true;
    #   users = ["alex"];
    # };

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

  # Bring in some audio
  security.rtkit.enable = true;
  # rtkit is optional but recommended
  services = {
    colord.enable = true;
    fprintd.enable = false;
    cpupower-gui.enable = true;

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/home/alex/shared/storage"];
    };

    borgbackup.jobs.all = rec {
      repo = "ssh://u278697-sub9@u278697.your-storagebox.de:23/./borg";
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

      gparted
      homebank

      powerstat # for measuring power consumption
      powercap # setting power consumption
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
