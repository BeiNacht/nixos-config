{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    # ../configs/borg.nix
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    # ../configs/libvirtd.nix
    ../configs/plasma-rdp.nix
    ../configs/services/frigate.nix
    ../configs/user.nix
    ../configs/virtualbox.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-homeserver.yaml;
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/2906-DD19";
    };
  };

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
          device = "/dev/disk/by-uuid/f6809a64-d23d-4940-a0e7-c256ce7a2e90";
          preLVM = true;
        };
      };
    };
    # kernelPackages = pkgs.linuxPackages_6_19;
    kernelParams = ["ip=dhcp"];
    kernelModules = ["kvm-intel"];
  };

  networking = {
    hostName = "homeserver";
    useDHCP = false;
    firewall = {enable = false;};
    interfaces = {
      enp1s0.useDHCP = true;
    };
    nftables.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      nyx
      snapraid
      mergerfs

      wayland-utils
      wl-clipboard
      xclip # Required for clipboard support over X11 RDP sessions
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/samba"
        "/var/lib/tor"
        "/var/lib/unifi"
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    coral.pcie.enable = true;
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

    #    netdata = {
    #      enable = true;
    #      package = pkgs.netdata.override {withCloudUi = true;};
    #      claimTokenFile = config.sops.secrets.netdata-token.path;
    #    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    # unifi = {
    #   enable = true;
    #   unifiPackage = pkgs.unifi;
    #   mongodbPackage = pkgs.mongodb-ce;
    # };

    # borgbackup.jobs.all = rec {
    #   # preHook = ''
    #   #   ${pkgs.libvirt}/bin/virsh shutdown hass
    #   #   until ${pkgs.libvirt}/bin/virsh list --all | grep "shut off"; do echo "Waiting for VM to shutdown......................."; sleep 1; done;
    #   # '';
    #   # postHook = ''
    #   #   ${pkgs.libvirt}/bin/virsh start hass
    #   # '';
    #   repo = "ssh://u278697-sub10@u278697.your-storagebox.de:23/./borg-homeserver";
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

    # zigbee2mqtt = {
    #   enable = true;
    # };

    samba = {
      enable = false;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "server";
          "netbios name" = "server";
          "security" = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "logging" = "systemd";
          "max log size" = 50;
          "invalid users" = [
            "root"
          ];
          "passwd program" = "/run/wrappers/bin/passwd %u";
        };
        storage = {
          "path" = "/home/alex/mounted/external";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        # timemachine = {
        #   "path" = "/home/alex/timemachine";
        #   "valid users" = "alex";
        #   "public" = "no";
        #   "writeable" = "yes";
        #   "force user" = "alex";
        #   "fruit:aapl" = "yes";
        #   "fruit:time machine" = "yes";
        #   "vfs objects" = "catia fruit streams_xattr";
        # };
      };
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "24.05";
}
