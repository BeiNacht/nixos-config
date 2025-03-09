{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/borg.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/libvirtd.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets-mini.yaml;
  };

  boot = {
    initrd = {
      availableKernelModules = ["r8169"];
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
    extraModulePackages = with pkgs.linuxPackages_latest; [rtl88x2bu];
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
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
  };

  services = {
    tor = {
      enable = true;
      # openFirewall = true;
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    borgbackup.jobs.all = rec {
      repo = "ssh://u278697-sub8@u278697.your-storagebox.de:23/./borg-backup-mini";
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
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

  systemd = {
    mounts = [
      {
        requires = ["mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount"];
        after = ["mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount"];
        what = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
        where = "/mnt/storage";
        type = "fuse.mergerfs";
        options = "defaults,allow_other,use_ino,fsname=mergerfs,minfreespace=50G,func.getattr=newest,noforget";
        wantedBy = ["multi-user.target"];
      }
    ];
  };

  system.stateVersion = "24.05";
}
