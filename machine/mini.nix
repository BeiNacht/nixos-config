{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ../configs/filesystem.nix
    ../configs/borg.nix
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/libvirtd.nix
    ../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-mini.yaml;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
    };

    "/home" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/01449b4a-4863-47dd-b213-5aefd014cd2d";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7222-8C3F";
    };

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
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/e59a0c55-7859-40ad-bf55-345708a67816";}
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "r8169"];
      kernelModules = ["dm-snapshot"];
      systemd.users.root.shell = "/bin/cryptsetup-askpass";
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
          ];
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

    kernelModules = ["kvm-intel"];
    # extraModulePackages = with pkgs.linuxPackages_latest; [rtl88x2bu];
  };

  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = {enable = false;};
    interfaces = {
      br0 = {
        useDHCP = true;
      };
    };

    bridges.br0.interfaces = ["enp3s0"];

    nftables.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      nyx
      snapraid
      mergerfs
    ];
    persistence."/persist" = {
      directories = [
        # "/var/lib/docker"
        "/var/lib/tor"
        "/var/lib/unifi"
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
  };

  services = {
    tor = {
      enable = true;
      # openFirewall = true;
    };

    netdata.enable = true;

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    unifi = {
      enable = true;
      unifiPackage = pkgs.unifi8;
      mongodbPackage = pkgs.mongodb-7_0;
    };

    borgbackup.jobs.all = rec {
      # preHook = ''
      #   ${pkgs.libvirt}/bin/virsh shutdown hass
      #   until ${pkgs.libvirt}/bin/virsh list --all | grep "shut off"; do echo "Waiting for VM to shutdown......................."; sleep 1; done;
      # '';
      # postHook = ''
      #   ${pkgs.libvirt}/bin/virsh start hass
      # '';
      repo = "ssh://u278697-sub8@u278697.your-storagebox.de:23/./borg-backup-mini";
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
        "/var/lib/libvirt/images"
      ];
    };

    locate = {
      prunePaths = ["/mnt" "/nix"];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "powersave";
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
