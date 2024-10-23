{ config, pkgs, lib, outputs, inputs, ... }:
let
  be = import ../../configs/borg-exclude.nix;
in
{
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
    ];
    config = {
      allowUnfree = true;
      # packageOverrides = pkgs: {
      #   intel-vaapi-driver =
      #     pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      # };
    };
  };

  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    inputs.sops-nix.nixosModules.sops
    ../../configs/browser.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/games.nix
    ../../configs/virtualisation.nix
    ../../configs/plasma-wayland.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

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
        sopsFile = ../../secrets-framework.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      hashedPassword = {
        neededForUsers = true;
      };
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = { canTouchEfiVariables = true; };
    };

    kernelPatches = [{
      name = "fix problems with netfilter in 6.11.4";
      patch = ../../kernelpatches/fix-netfilter-6.11.4.patch;
    }];

    tmp.useTmpfs = false;
  };

  # nixpkgs.localSystem = {
  #   gcc.arch = "alderlake";
  #   gcc.tune = "alderlake";
  #   system = "x86_64-linux";
  # };

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-alderlake"
  ];

  networking = {
    hostName = "framework";
  };

  time.timeZone = "Europe/Berlin";

  programs.fw-fanctrl = {
    enable = false;
    config = {
      defaultStrategy = "lazy";
      strategies = {
        "lazy" = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            { temp = 0; speed = 15; }
            { temp = 50; speed = 15; }
            { temp = 65; speed = 25; }
            { temp = 70; speed = 35; }
            { temp = 75; speed = 50; }
            { temp = 85; speed = 100; }
          ];
        };
      };
    };
  };

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    openrazer = {
      enable = true;
      users = [ "alex" ];
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
    # foldingathome.enable = true;
    power-profiles-daemon.enable = true;
    colord.enable = true;

    fwupd.enable = true;

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/home/alex/shared/storage" ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-key.path}";
      };
      extraCreateArgs =
        "--stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_ed25519";
      paths = [ "/home/alex" "/var/lib" ];
      repo = "ssh://u278697-sub9@u278697.your-storagebox.de:23/./borg";
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: "/home/alex/" + x) be.borg-exclude;
    };

    tailscale.enable = true;
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
    sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver
    systemPackages = with pkgs; [
      # psensor
      mission-center
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

  # Set up deep sleep + hibernation
  swapDevices = [{
    device = "/swapfile";
    size = 64 * 1024;
  }];

  # Partition swapfile is on (after LUKS decryption)
  boot.resumeDevice = "/dev/disk/by-uuid/5549d49d-165e-4a45-973e-6a32a63e31be";

  # Resume Offset is offset of swapfile
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=190937088" ];

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
