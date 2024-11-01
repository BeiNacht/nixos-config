{ config, pkgs, inputs, outputs, ... }:
let
  be = import ../../configs/borg-exclude.nix;
in
{
  nixpkgs = {
    overlays = [
      (self: super: {
        linuxPackages_cachyos-rc = super.linuxPackages_cachyos-rc.extend (lpself: lpsuper: {
          xone = super.linuxPackages_cachyos-rc.xone.overrideAttrs (oldAttrs: rec {
            version = "0-unstable-latest";
            patches = [
              # Fix build on kernel 6.11
              # https://github.com/medusalix/xone/pull/48
              (pkgs.fetchpatch {
                name = "kernel-6.11.patch";
                url = "https://github.com/medusalix/xone/commit/28df566c38e0ee500fd5f74643fc35f21a4ff696.patch";
                hash = "sha256-X14oZmxqqZJoBZxPXGZ9R8BAugx/hkSOgXlGwR5QCm8=";
              })

              (pkgs.fetchpatch {
                name = "kernel-6.12.patch";
                url = "https://github.com/medusalix/xone/commit/d88ea1e8b430d4b96134e43ca1892ac48334578e.patch";
                hash = "sha256-zQK1tuxu2ZmKxPO0amkfcT/RFBSkU2pWD0qhGyCCHXI=";
              })
            ];

          });
        });
      })
    ];

    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
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

  nix.settings = {
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
      "gccarch-znver2"
    ];
    trusted-substituters = [ "https://ai.cachix.org" ];
    trusted-public-keys = [ "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc=" ];
  };

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

    tmp.useTmpfs = false;
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = pkgs.pkgs.linuxPackages_cachyos-rc;
    kernelModules = [ "nct6775" ];
    extraModulePackages = with pkgs.pkgs.linuxPackages_cachyos-rc; [ ryzen-smu ];
    # kernelParams = [ "clearcpuid=514" ];
    # kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
    # kernelPatches = [{
    #   name = "fix problems with netfilter in 6.11.4";
    #   patch = ../../kernelpatches/fix-netfilter-6.11.4.patch;
    # }];

    initrd = {
      luks.devices = {
        root = {
          # Use https://nixos.wiki/wiki/Full_Disk_Encryption
          device = "/dev/disk/by-uuid/cc43f1eb-49c3-41a6-9279-6766de3659e7";
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

  environment.persistence."/persist" = {
    directories = [
      "/etc/coolercontrol"
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
      "/var/lib/bluetooth"
      "/var/lib/docker"
      "/var/lib/nixos"
      "/var/lib/samba"
      "/var/lib/sddm"
      "/var/lib/systemd/rfkill"
      "/var/lib/tailscale"
      "/var/lib/tuptime"
      "/var/lib/vnstat"
    ];
    files = [
      # "/etc/machine-id"
      "/etc/NIXOS"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  systemd.services = {
    monitor = {
      description = "AMDGPU Control Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = { ExecStart = "${pkgs.lact}/bin/lact daemon"; };
    };
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
    lact
    amdgpu_top

    python3
    python311Packages.tkinter

    snapraid
    mergerfs
    gimp

    clinfo
    gparted
    mission-center
    resources
    stressapptest
    ryzen-monitor-ng
    qdiskinfo
    #    fan2go
    #    unigine-superposition

    jdk
    moonlight-qt
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

    pulseaudio.enable = false;
  };

  programs = {
    coolercontrol.enable = true;
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
    };
  };

  # powerManagement = {
  #   enable = true;
  #   powertop.enable = true;
  # };

  services = {
    power-profiles-daemon.enable = true;
    # netdata.enable = true;
    # printing.enable = true;
    fwupd.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    sunshine = {
      enable = true;
      capSysAdmin = true;
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

    # jellyfin = {
    #   enable = true;
    #   user = "alex";
    #   group = "users";
    # };

    tailscale.enable = true;

    borgbackup.jobs = {
      home = rec {
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

      # home-external = rec {
      #   compression = "auto,zstd";
      #   encryption = {
      #     mode = "repokey-blake2";
      #     passCommand = "cat ${config.sops.secrets.borg-key.path}";
      #   };
      #   extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
      #   paths = "/home/alex";
      #   repo = "/run/media/alex/b6c33623-fc23-47ed-b6f5-e99455d5534a/borg";
      #   startAt = [ ];
      #   user = "alex";
      #   prune.keep = {
      #     daily = 7;
      #     weekly = 4;
      #     monthly = 6;
      #   };
      #   extraPruneArgs = "--save-space --list --stats";
      #   exclude = map (x: paths + "/" + x) [
      #     ".cache"
      #     ".config/Nextcloud/logs"
      #     ".local/share/baloo"
      #   ];
      # };
    };
  };

  security = {
    rtkit.enable = true;
    apparmor.enable = true;

    auditd.enable = true;
    audit.enable = true;
    audit.rules = [
      "-a exit,always -F arch=b64 -S execve"
    ];

    sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';
  };

  system.stateVersion = "24.11";
}
