{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: let
  # ext4 SnapRAID set (USB), by ext4 filesystem UUID. Being converted in place
  # to LUKS2 with scripts/encrypt-backup-disk.sh; once a disk is done, add it
  # to encryptedBackupDisks so it's unlocked (label <disk>-crypt) and mounted
  # from /dev/mapper/<disk>.
  backupDiskUuids = {
    disk1 = "3c4b5d00-43c0-48be-81b8-c2b3977e015b";
    disk2 = "98a75e01-fa80-469e-820c-1e1e275937b8";
    disk3 = "0301db98-264f-4b18-9423-15691063f73d";
    parity = "6cce037c-d2d4-4940-bb69-6d2b84fd41aa";
  };
  encryptedBackupDisks = [];
  backupDataDisks = ["disk1" "disk2" "disk3"];
  backupDisks = builtins.attrNames backupDiskUuids;
in {
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
    ../configs/printing.nix
    ../configs/samba.nix
    ../configs/sunshine.nix
    ../configs/user-gui.nix
    ../configs/user.nix
    # (modulesPath + "/installer/scan/not-detected.nix")
  ];

  sops = {
    secrets = {
      borg-key = {
        sopsFile = ../secrets/secrets-desktop.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  # Hot-swappable drives: LUKS "storage" (USB) and "internal-storage" (SATA),
  # plus the ext4 backup set disk1-3 + parity (SnapRAID, data disks pooled by
  # mergerfs, LUKS where listed in encryptedBackupDisks). None is required for boot (nofail). Plugging a LUKS
  # drive in unlocks it via udev; the first access to a mount point mounts it
  # via automount. Use `sudo storage-hotswap eject <name>` before pulling one.
  fileSystems = let
    hotswapOptions = [
      "noatime"
      "noauto" # Don't mount at boot
      "x-systemd.automount" # Mount on first access
      "x-systemd.idle-timeout=10min" # Unmount after 10 mins of silence
      "x-systemd.device-timeout=10s" # Fail fast if the drive isn't plugged in
      "nofail" # Boot proceeds normally if the drive is missing
    ];
    hotswapBtrfs = mapper: {
      device = "/dev/mapper/${mapper}"; # pulls in systemd-cryptsetup@<mapper>.service
      fsType = "btrfs";
      options = ["autodefrag" "compress=zstd" "nodiratime"] ++ hotswapOptions;
    };
    hotswapExt4 = d: uuid: {
      device =
        if lib.elem d encryptedBackupDisks
        then "/dev/mapper/${d}"
        else "/dev/disk/by-uuid/${uuid}";
      fsType = "ext4";
      options = hotswapOptions;
    };
  in
    {
      "/home/alex/shared/storage" = hotswapBtrfs "storage";
      # "/home/alex/shared/internal-storage" = hotswapBtrfs "internal-storage";
    }
    // lib.mapAttrs' (d: uuid: lib.nameValuePair "/home/alex/shared/${d}" (hotswapExt4 d uuid)) backupDiskUuids
    // {
      # mergerfs pool over disk1-3. Accessing it mounts all three data disks
      # first (requires-mounts-for); if one is missing the pool fails to mount.
      "/home/alex/shared/backup" = {
        device = lib.concatMapStringsSep ":" (d: "/home/alex/shared/${d}") backupDataDisks;
        fsType = "fuse.mergerfs";
        options =
          [
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=10min"
            "nofail"
            "fsname=backup"
            "allow_other"
            "cache.files=off"
            "category.create=mfs" # new files go to the disk with the most free space
            "moveonenospc=true"
            "minfreespace=100G"
            "dropcacheonclose=true"
          ]
          ++ map (d: "x-systemd.requires-mounts-for=/home/alex/shared/${d}") backupDataDisks;
      };
    };
  system.fsPackages = [pkgs.mergerfs];

  environment.etc.crypttab.text = ''
    storage UUID=fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1 /persist/hdd.key nofail,x-systemd.device-timeout=10s
    internal-storage UUID=db454a2d-ebc0-4503-8a76-dcc23c7a79ea /persist/internal-hdd.key nofail,x-systemd.device-timeout=10s
    ${lib.concatMapStrings (d: "${d} LABEL=${d}-crypt /persist/backup-hdd.key nofail,x-systemd.device-timeout=10s\n") encryptedBackupDisks}'';

  systemd.tmpfiles.rules = ["d /persist/snapraid 0700 root root -"];

  nix.settings = {
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
      "gccarch-znver3"
    ];
    max-jobs = 4;
  };

  boot = {
    tmp.useTmpfs = false;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["clearcpuid=514" "ip=dhcp"];
    kernelModules = ["nct6775"];
    kernel.sysctl = {
      "vm.nr_hugepages" = 1280;
    };
    initrd = {
      # availableKernelModules = ["r8169"];
      # systemd.users.root.shell = "/bin/cryptsetup-askpass";
      # network = {
      #   enable = true;
      #   ssh = {
      #     enable = true;
      #     port = 22;
      #     authorizedKeys = [
      #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
      #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
      #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
      #     ];
      #     hostKeys = ["/persist/pre_boot_ssh_host_rsa_key"];
      #   };
      # };

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/ad6eaac3-97e1-46cf-83df-ddcc5004dfc0";
          allowDiscards = true;
          preLVM = true;
        };
      };
    };
  };

  # powertop --auto-tune (enabled in configs/hardware.nix for the laptop) saves
  # only a few watts here, but autosuspends USB input devices (laggy wireless
  # mouse) and runtime-suspends SATA ports (hot-swap bays miss inserted drives).
  powerManagement.powertop.enable = lib.mkForce false;

  systemd = {
    services = {
      # Manual-only: no timers, and make sure every disk is mounted first.
      snapraid-sync = {
        startAt = lib.mkForce [];
        unitConfig.RequiresMountsFor = map (d: "/home/alex/shared/${d}") backupDisks;
      };
      snapraid-scrub = {
        startAt = lib.mkForce [];
        unitConfig.RequiresMountsFor = map (d: "/home/alex/shared/${d}") backupDisks;
      };
      monitor = {
        description = "AMDGPU Control Daemon";
        wantedBy = ["multi-user.target"];
        after = ["multi-user.target"];
        serviceConfig = {ExecStart = "${pkgs.lact}/bin/lact daemon";};
      };
    };
  };

  networking = {
    hostName = "desktop";
  };

  programs = {
    coolercontrol.enable = true;
    corectrl = {
      enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      lact
      amdgpu_top
      # Reads zenpower (CPU) + amdgpu_top (GPU) sensors, both desktop-only.
      (writeShellScriptBin "power-draw" (builtins.readFile ../home/bin/power-draw))
      # python3
      # python311Packages.tkinter
      gimp
      clinfo
      # mission-center
      stressapptest
      #ryzen-monitor-ng
      jdk

      xmrig
      monero-gui

      snapraid
      smartmontools
      mergerfs

      (writeShellApplication {
        name = "storage-hotswap";
        runtimeInputs = [coreutils util-linux systemd cryptsetup];
        text = builtins.readFile ../home/bin/storage-hotswap;
      })
    ];
    persistence."/persist" = {
      directories = [
        "/etc/coolercontrol"
        "/var/lib/samba"
        "/var/lib/systemd/rfkill"
        {
          directory = "/var/lib/private";
          mode = "0700";
        }
        # "/var/lib/open-webui"   # if you enable open-webui
      ];
    };
  };

  # Build btop with rocm-smi in its runpath so it can dlopen librocm_smi64
  # and show AMD GPU usage.
  nixpkgs.overlays = [
    (final: prev: {btop = prev.btop.override {rocmSupport = true;};})
  ];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
    amdgpu = {
      overdrive.enable = true;
      initrd.enable = true;
    };

    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        clinfo
        rocmPackages.clr.icd
        rocmPackages.rocminfo
        rocmPackages.rocm-runtime
      ];
    };
  };

  services = {
    # netdata.enable = true;
    # printing.enable = true;
    bpftune.enable = true;

    snapraid = {
      enable = true;
      dataDisks = lib.genAttrs backupDataDisks (d: "/home/alex/shared/${d}/");
      parityFiles = ["/home/alex/shared/parity/snapraid.parity"];
      contentFiles =
        map (d: "/home/alex/shared/${d}/.snapraid.content") backupDataDisks
        ++ ["/persist/snapraid/snapraid.content"];
      exclude = [
        "*.unrecoverable"
        "/tmp/"
        "/lost+found/"
      ];
    };

    samba.settings.storage = {
      browseable = "yes";
      "guest ok" = "no";
      path = "/home/alex/shared/storage";
      "read only" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
    };

    borgbackup.jobs.all = rec {
      repo = "ssh://alex@mini.meteor-altered.ts.net/./homeserver/storage/samba/desktop/borg";
    };

    udev.extraRules = ''
      SUBSYSTEM=="powercap", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod o+r /sys%p/energy_uj"
      # Keep SATA ports awake so hot-inserted drives are detected (see sata-hotplug)
      SUBSYSTEM=="ata_port", ACTION=="add", TEST=="device/power/control", ATTR{device/power/control}="on"
      # Unlock hot-plugged LUKS drives as soon as they appear
      SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_UUID}=="fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@storage.service"
      SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_UUID}=="db454a2d-ebc0-4503-8a76-dcc23c7a79ea", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@internal\x2dstorage.service"
      ${lib.concatMapStrings (d: ''SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="crypto_LUKS", ENV{ID_FS_LABEL}=="${d}-crypt", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@${d}.service"'' + "\n") encryptedBackupDisks}'';

    ollama = {
      enable = true;
      package = pkgs.ollama-rocm; # ROCm build; use pkgs.ollama-vulkan if ROCm gives you trouble
      # rocmOverrideGfx = "12.0.1"; # only if it doesn't detect the GPU (gfx1201)
      # host = "0.0.0.0"; openFirewall = true;  # only if other machines should reach it
    };
    # Optional ChatGPT-style web UI at http://localhost:8080
    # open-webui.enable = true;
  };

  system.stateVersion = "25.11";
}
