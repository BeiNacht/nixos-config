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
    defaultSopsFile = ../secrets/secrets-homeserver.yaml;
    secrets = {
      netdata-token = {
        owner = config.services.netdata.user;
        group = config.services.netdata.group;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/99bebe82-b399-455a-af0f-3bb2384e2d6f";
    };

    "/home" = {
      device = "/dev/disk/by-uuid/99bebe82-b399-455a-af0f-3bb2384e2d6f";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/99bebe82-b399-455a-af0f-3bb2384e2d6f";
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/99bebe82-b399-455a-af0f-3bb2384e2d6f";
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/99bebe82-b399-455a-af0f-3bb2384e2d6f";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/1C72-6F6E";
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/9ea87328-c50b-4a93-8cd1-3fabfa5791b6";}
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "igc"];
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
          device = "/dev/disk/by-uuid/1bfbde8d-c669-4c95-8e40-9aaddb07d0c9";
          preLVM = true;
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["ip=dhcp"];
    kernelModules = ["kvm-intel"];
  };

  networking = {
    hostName = "homeserver";
    firewall = {enable = false;};
    nftables.enable = true;
    useDHCP = false;
    bridges = {
      br0 = {
        interfaces = [
          "enp1s0"
          "enp2s0"
          "enp3s0"
          "enp4s0"
        ];
        rstp = true;
      };
    };
    interfaces = {
      br0.useDHCP = true;
      enp1s0.useDHCP = false;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      nyx
      snapraid
      mergerfs
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/tor"
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
      #   # openFirewall = true;
    };

    # suricata = {
    #   enable = true;
    #   settings = {
    #     vars.address-groups.HOME_NET = "192.168.178.0/24";
    #     outputs = [
    #       {
    #         fast = {
    #           enabled = true;
    #           filename = "fast.log";
    #           append = "yes";
    #         };
    #       }
    #       {
    #         eve-log = {
    #           enabled = true;
    #           filetype = "regular";
    #           filename = "eve.json";
    #           community-id = true;
    #           types = [
    #             {
    #               alert.tagged-packets = "yes";
    #             }
    #           ];
    #         };
    #       }
    #     ];
    #     af-packet = [
    #       {
    #         interface = "br0";
    #         cluster-id = "99";
    #         cluster-type = "cluster_flow";
    #         defrag = "yes";
    #       }
    #       {
    #         interface = "default";
    #       }
    #     ];
    #     af-xdp = [
    #       {
    #         interface = "br0";
    #       }
    #     ];
    #     dpdk.interfaces = [
    #       {
    #         interface = "br0";
    #       }
    #     ];
    #     pcap = [
    #       {
    #         interface = "br0";
    #       }
    #     ];
    #     app-layer.protocols = {
    #       telnet.enabled = "yes";
    #       dnp3.enabled = "yes";
    #       modbus.enabled = "yes";
    #     };
    #   };
    # };

    netdata = {
      enable = true;
      package = pkgs.netdata.override {withCloudUi = true;};
      claimTokenFile = config.sops.secrets.netdata-token.path;
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    borgbackup.jobs.all = rec {
      # preHook = ''
      #   ${pkgs.libvirt}/bin/virsh shutdown hass
      #   until ${pkgs.libvirt}/bin/virsh list --all | grep "shut off"; do echo "Waiting for VM to shutdown......................."; sleep 1; done;
      # '';
      # postHook = ''
      #   ${pkgs.libvirt}/bin/virsh start hass
      # '';
      repo = "ssh://u278697-sub8@u278697.your-storagebox.de:23/./borg-backup-homeserver";
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

  system.stateVersion = "24.05";
}
