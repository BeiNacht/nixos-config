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
    ../../configs/browser.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/games.nix
    ../../configs/virtualisation.nix
    ../../configs/plasma.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
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
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        configurationLimit = 5;
        # enableCryptodisk = true;
      };
      efi = {canTouchEfiVariables = true;};
    };

    tmp.useTmpfs = false;
    supportedFilesystems = ["btrfs"];
    kernelPackages = pkgs.linuxPackages_6_11;

    initrd = {
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/eddab069-d369-4b26-8b4e-f3b907ba6f6c";
          allowDiscards = true;
          preLVM = true;
        };
      };

      postDeviceCommands = pkgs.lib.mkBefore ''
        mkdir -p /mnt

        # We first mount the btrfs root to /mnt
        # so we can manipulate btrfs subvolumes.
        mount -o subvol=/ /dev/mapper/lvm-root /mnt

        # While we're tempted to just delete /root and create
        # a new snapshot from /root-blank, /root is already
        # populated at this point with a number of subvolumes,
        # which makes `btrfs subvolume delete` fail.
        # So, we remove them first.
        #
        # /root contains subvolumes:
        # - /root/var/lib/portables
        # - /root/var/lib/machines
        #
        # I suspect these are related to systemd-nspawn, but
        # since I don't use it I'm not 100% sure.
        # Anyhow, deleting these subvolumes hasn't resulted
        # in any issues so far, except for fairly
        # benign-looking errors from systemd-tmpfiles.
        btrfs subvolume list -o /mnt/root |
        cut -f9 -d' ' |
        while read subvolume; do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "/mnt/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete /mnt/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /mnt/root-blank /mnt/root

        # Once we're done rolling back to a blank snapshot,
        # we can unmount /mnt and continue on the boot process.
        umount /mnt
      '';
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
    persistence."/persist" = {
      directories = [
        "/etc/NetworkManager/system-connections"
        # "/var/lib/bluetooth"
        "/var/lib/docker"
        "/var/lib/nixos"
        # "/var/lib/samba"
        "/var/lib/sddm"
        # "/var/lib/systemd/rfkill"
        "/var/lib/tailscale"
        "/var/lib/tuptime"
        "/var/lib/vnstat"
      ];
      files = [
        "/etc/machine-id"
        "/etc/NIXOS"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
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
