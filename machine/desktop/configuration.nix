{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: let
  be = import ../../configs/borg-exclude.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../configs/browser.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/games.nix
    ../../configs/develop.nix
    ../../configs/hardware.nix
    ../../configs/virtualbox.nix
    ../../configs/plasma.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      borg-key = {
        sopsFile = ../../secrets/secrets-desktop.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };
    };
  };

  nix.settings = {
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
      "gccarch-znver3"
    ];
    max-jobs = 4;

    trusted-substituters = ["https://ai.cachix.org"];
    trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];
  };

  # nixpkgs.localSystem = {
  #   gcc.arch = "znver3";
  #   gcc.tune = "znver3";
  #   system = "x86_64-linux";
  # };

  boot = {
    tmp.useTmpfs = false;
    kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = ["clearcpuid=514" "ip=dhcp"];
    kernelModules = ["nct6775"];
    kernel.sysctl = {
      "vm.nr_hugepages" = 1280;
    };
    extraModulePackages = with pkgs.linuxPackages_cachyos; [ryzen-smu];
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
          hostKeys = ["/persist/pre_boot_ssh_host_rsa_key"];
        };
      };

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/cc43f1eb-49c3-41a6-9279-6766de3659e7";
          allowDiscards = true;
          preLVM = true;
        };
      };
    };
  };

  chaotic.mesa-git.enable = true;

  systemd.services = {
    monitor = {
      description = "AMDGPU Control Daemon";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      serviceConfig = {ExecStart = "${pkgs.lact}/bin/lact daemon";};
    };
  };

  networking = {
    hostName = "desktop";
  };

  time.timeZone = "Europe/Berlin";

  programs = {
    coolercontrol.enable = true;
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      lact
      amdgpu_top
      # python3
      # python311Packages.tkinter
      # snapraid
      # mergerfs
      gimp
      clinfo
      gparted
      # mission-center
      resources
      stressapptest
      ryzen-monitor-ng
      qdiskinfo
      jdk

      xmrig
      monero-gui
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
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      # doesnt build atm
      # extraPackages = with pkgs; [rocmPackages.clr.icd];
    };

    # cpu.x86.msr = {
    #   enable = true;
    # };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services = {
    power-profiles-daemon.enable = true;
    # netdata.enable = true;
    # printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
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

    borgbackup.jobs = {
      home = rec {
        compression = "auto,zstd";
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets.borg-key.path}";
        };
        extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
        environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_ed25519";
        paths = ["/home/alex" "/persist"];
        repo = "ssh://u278697-sub2@u278697.your-storagebox.de:23/./borg";
        startAt = "daily";
        prune.keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
        extraPruneArgs = "--save-space --list --stats";
        exclude = map (x: "/home/alex/" + x) be.borg-exclude;
      };
    };
  };

  system.stateVersion = "24.11";
}
