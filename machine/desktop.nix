{
  config,
  pkgs,
  inputs,
  outputs,
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
    ../configs/libvirtd.nix
    ../configs/plasma.nix
    ../configs/printing.nix
    ../configs/user-gui.nix
    ../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      borg-key = {
        sopsFile = ../secrets/secrets-desktop.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/lvm-root";
    };

    "/home" = {
      device = "/dev/mapper/lvm-root";
    };

    "/nix" = {
      device = "/dev/mapper/lvm-root";
    };

    "/persist" = {
      device = "/dev/mapper/lvm-root";
    };

    "/var/log" = {
      device = "/dev/mapper/lvm-root";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7061-25CD";
    };

   "/home/alex/shared/storage" = {
     device = "/dev/disk/by-uuid/9a85d05a-2d26-47e9-803a-f10740d9eafa";
     fsType = "btrfs";
     options = [
       "autodefrag"
       "compress=zstd"
       "nodiratime"
       "noatime"
     ];
   };
  };

 environment.etc.crypttab.text = ''
   storage UUID=fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1 /persist/hdd.key
 '';

  swapDevices = [{device = "/dev/mapper/lvm-swap";}];

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

#  chaotic.mesa-git.enable = true;

#  systemd = {
#    services = {
#      monitor = {
#        description = "AMDGPU Control Daemon";
#        wantedBy = ["multi-user.target"];
#        after = ["multi-user.target"];
#        serviceConfig = {ExecStart = "${pkgs.lact}/bin/lact daemon";};
#      };
#    };
#  };

  networking = {
    hostName = "desktop";
  };

  programs = {
    coolercontrol.enable = true;
#    corectrl = {
#      enable = true;
#      # gpuOverclock.enable = true;
#    };
  };

  environment = {
    systemPackages = with pkgs; [
      lact
      amdgpu_top
      # python3
      # python311Packages.tkinter
      gimp
      clinfo
      gparted
      # mission-center
      resources
      stressapptest
      #ryzen-monitor-ng
      qdiskinfo
      jdk

      haruna

      xmrig
      monero-gui

      snapraid
      mergerfs
    ];
    persistence."/persist" = {
      directories = [
        "/etc/coolercontrol"
        "/var/lib/samba"
        "/var/lib/systemd/rfkill"
      ];
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
      #ryzen-smu.enable = true;
    };
#    amdgpu = {
#      overdrive.enable = true;
#      initrd.enable = true;
#    };

    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      # doesnt build atm
#      extraPackages = with pkgs; [
#        clinfo
#        rocmPackages.clr.icd
#        rocmPackages.rocminfo
#        rocmPackages.rocm-runtime
#      ];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services = {
    # netdata.enable = true;
    # printing.enable = true;
    bpftune.enable = true;

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
        storage = {
          browseable = "yes";
          "guest ok" = "no";
          path = "/home/alex/shared/storage";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    borgbackup.jobs.all = rec {
      repo = "ssh://u278697-sub2@u278697.your-storagebox.de:23/./borg";
    };
  };

  system.stateVersion = "25.11";
}
