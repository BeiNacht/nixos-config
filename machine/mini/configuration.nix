{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/docker.nix
    ../../configs/common-linux.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      borg-key = {
        sopsFile = ../../secrets/secrets-mini.yaml;
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      hashedPassword = {
        neededForUsers = true;
      };
    };
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

  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = {enable = false;};
    interfaces = {
      enp3s0.useDHCP = true;
    };

    nftables.enable = true;
    # wireguard.interfaces = {
    #   wg0 = {
    #     ips = [ "10.100.0.3/24" ];
    #     privateKey = secrets.wireguard-mini-private;

    #     postSetup = ''
    #       ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
    #     '';

    #     # This undoes the above command
    #     postShutdown = ''
    #       ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
    #     '';
    #   };
    # };

    # nat = {
    #   enable = true;
    #   enableIPv6 = true;
    #   # externalInterface = "enp3s0";
    #   # internalInterfaces = [ "tailscale0" ];
    # };

    # wireless = {
    #   enable = true;
    #   networks.Skynet.psk = secrets.wifipassword;
    #   interfaces = [ "wlp0s20u1u1" ];
    # };
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

    # hostapd = {
    #   enable = true;
    #   radios = {
    #     wlp0s20u1u2 = {
    #       # wifi4.enable = false;
    #       # wifi5.enable = false;
    #       # settings.ieee80211n = true; # otherwise enabled by wifi4.enable
    #       networks.wlp0s20u1u2 = {
    #         ssid = "Skynet-Tor";
    #         authentication.saePasswords = [
    #           { password = "REMOVED_OLD_PASSWORD_FROM_HISTORY"; }
    #         ];
    #       };

    #     };
    #   };
    # };

    # dnsmasq = {
    #   enable = true;
    #   extraConfig = ''
    #     interface=wlp0s20u1u2
    #     bind-interfaces
    #     dhcp-range=192.168.12.10,192.168.12.254,24h
    #   '';
    # };

    # kea.dhcp4 = {
    #   enable = true;
    #   # interfaces = [ "wlp0s20u1u2" ];
    #   settings = {
    #     interfaces-config = {
    #       interfaces = [
    #         "wlp0s20u1u2"
    #       ];
    #     };
    #     lease-database = {
    #       name = "/var/lib/kea/dhcp4.leases";
    #       persist = true;
    #       type = "memfile";
    #     };
    #     rebind-timer = 2000;
    #     renew-timer = 1000;
    #     subnet4 = [
    #       {
    #         pools = [
    #           {
    #             pool = "192.168.12.100 - 192.168.12.240";
    #           }
    #         ];
    #         subnet = "192.168.12.0/24";
    #       }
    #     ];
    #     valid-lifetime = 4000;
    #   };
    # };

    # haveged.enable = true;

    # k3s = {
    #   enable = true;
    #   role = "server";
    # };

    # printing = {
    #   enable = true;
    #   drivers = [ pkgs.brlaser ];
    #   browsing = true;
    #   listenAddresses = [
    #     "*:631"
    #   ]; # Not 100% sure this is needed and you might want to restrict to the local network
    #   allowFrom = [
    #     "all"
    #   ]; # this gives access to anyone on the interface you might want to limit it see the official documentation
    #   defaultShared = true; # If you want
    # };

    # avahi = {
    #   enable = true;
    #   publish.enable = true;
    #   publish.userServices = true;
    # };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = "--advertise-exit-node --login-server=https://headscale.szczepan.ski";
    };

    borgbackup.jobs.home = rec {
      repo = "ssh://u278697-sub8@u278697.your-storagebox.de:23/./borg-backup-mini";

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
        BORG_RSH = "ssh -i /home/alex/.ssh/id_ed55129";
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
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
      ];
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
