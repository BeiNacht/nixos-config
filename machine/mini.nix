{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: let
  sshKeys = import ../configs/ssh-keys.nix;
in {
  imports = [
    ../configs/filesystem.nix
    # ../configs/borg.nix
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/samba.nix
    ../configs/user.nix
  ];

  users.users.alex.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/tghG2pBTrqYT4+1nF1266lteRBf2bPL+OZAOjyFHL alex@vps-arm"
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-mini.yaml;
  };

  fileSystems = {
    # "/mnt/disk1" = {
    #   device = "/dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b";
    #   fsType = "ext4";
    #   options = ["nofail" "x-systemd.automount"];
    # };

    # "/mnt/disk2" = {
    #   device = "/dev/disk/by-uuid/98a75e01-fa80-469e-820c-1e1e275937b8";
    #   fsType = "ext4";
    #   options = ["nofail" "x-systemd.automount"];
    # };

    # "/mnt/disk3" = {
    #   device = "/dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d";
    #   fsType = "ext4";
    #   options = ["nofail" "x-systemd.automount"];
    # };

    # "/mnt/parity" = {
    #   device = "/dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa";
    #   fsType = "ext4";
    #   options = ["nofail" "x-systemd.automount"];
    # };

    "/boot" = {
      device = pkgs.lib.mkForce "/dev/disk/by-uuid/7222-8C3F";
    };

    "/home/alex/homeserver/storage" = {
      device = "/dev/disk/by-uuid/8525a64b-4765-468f-8ca9-08544b42fbc7";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };

    # "/home/alex/homeserver/share" = {
    #   device = "/dev/disk/by-uuid/9a85d05a-2d26-47e9-803a-f10740d9eafa";
    #   fsType = "btrfs";
    #   options = [
    #     "autodefrag"
    #     "compress=zstd"
    #     "nodiratime"
    #     "noatime"
    #     "noauto" # Don't mount at boot
    #     "x-systemd.automount" # Enable systemd automounting
    #     "x-systemd.idle-timeout=10min" # Optional: auto-unmount/lock after 10 mins of silence
    #     "x-systemd.device-timeout=5s" # Don't freeze the system if the USB isn't plugged in
    #     "nofail" # Boot proceeds normally if USB is missing
    #   ];
    # };
  };

  environment.etc.crypttab.text = ''
    storage UUID=fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1 /persist/hdd.key
  '';

  swapDevices = [{device = "/dev/mapper/lvm-swap";}];

  boot = {
    kernelModules = ["kvm-intel"];
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "r8169"];
      kernelModules = ["dm-snapshot"];
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = sshKeys.initrd;
          hostKeys = ["/persist/pre_boot_ssh_key"];
        };
      };
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/9287df9c-ec3c-4cd8-af3a-d253f9418f7b";
          preLVM = true;
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # extraModulePackages = with pkgs.linuxPackages_latest; [rtl88x2bu];
  };

  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = {enable = false;};
    interfaces = {
      enp3s0.useDHCP = true;
    };
    nftables.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      nyx
      snapraid
      mergerfs
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/samba"
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    samba = {
      settings = {
        storage = {
          "path" = "/home/alex/homeserver/storage";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        share = {
          "path" = "/home/alex/homeserver/share";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        homeassistant = {
          "path" = "/home/alex/homeserver/storage/homeassistant";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        timemachine = {
          "path" = "/home/alex/homeserver/storage/timemachine";
          "valid users" = "alex";
          "public" = "no";
          "writeable" = "yes";
          "force user" = "alex";
          "fruit:aapl" = "yes";
          "fruit:time machine" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
        };
      };
    };

    # borgbackup.jobs.all = rec {
    #   # preHook = ''
    #   #   ${pkgs.libvirt}/bin/virsh shutdown hass
    #   #   until ${pkgs.libvirt}/bin/virsh list --all | grep "shut off"; do echo "Waiting for VM to shutdown......................."; sleep 1; done;
    #   # '';
    #   # postHook = ''
    #   #   ${pkgs.libvirt}/bin/virsh start hass
    #   # '';
    #   repo = "ssh://u278697-sub8@u278697.your-storagebox.de:23/./borg-backup-mini";
    #   exclude = [
    #     "/home/alex/mounted"
    #     "/home/alex/.cache"
    #     "/persist/borg"
    #     "/var/lib/libvirt/images"
    #   ];
    # };

    locate = {
      prunePaths = ["/mnt" "/nix"];
    };
  };

  # systemd = {
  #   mounts = [
  #     {
  #       requires = ["mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount"];
  #       after = ["mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount"];
  #       what = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
  #       where = "/mnt/storage";
  #       type = "fuse.mergerfs";
  #       options = "defaults,allow_other,use_ino,fsname=mergerfs,minfreespace=50G,func.getattr=newest,noforget";
  #       wantedBy = ["multi-user.target"];
  #     }
  #   ];
  # };

  system.stateVersion = "24.05";
}
