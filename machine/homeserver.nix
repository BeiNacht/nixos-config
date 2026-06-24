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
    ../configs/plasma-desktop.nix
    ../configs/games.nix
    ../configs/services/frigate.nix
    ../configs/user.nix
    ../configs/virtualbox.nix
  ];

  users.users.alex.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/tghG2pBTrqYT4+1nF1266lteRBf2bPL+OZAOjyFHL alex@vps-arm"
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-homeserver.yaml;
  };

  fileSystems = {
    "/home/alex/homeserver/storage" = {
      device = "/dev/disk/by-uuid/8525a64b-4765-468f-8ca9-08544b42fbc7";
      fsType = "ext4";
      options = ["nofail" "x-systemd.automount"];
    };
  };

  boot = {
    kernelModules = ["kvm-intel"];
    kernelParams = ["ip=dhcp"];
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "igc"];
      kernelModules = ["dm-snapshot"];
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
        "/var/lib/zigbee2mqtt"
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    coral.pcie.enable = true;
  };

  services = {
    # tor = {
    #   enable = true;
    #   #   # openFirewall = true;
    # };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    # unifi = {
    #   enable = true;
    #   unifiPackage = pkgs.unifi;
    #   mongodbPackage = pkgs.mongodb-ce;
    # };

    locate = {
      prunePaths = ["/mnt" "/nix"];
    };

    samba = {
      enable = true;
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
          "path" = "/home/alex/homeserver/storage";
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
  };

  # powerManagement = {
  #   enable = true;
  #   powertop.enable = true;
  #   # cpuFreqGovernor = "powersave";
  # };

  # virtualisation = {
  #   oci-containers = {
  #     backend = "podman";
  #     containers.homeassistant = {
  #       volumes = ["home-assistant:/config"];
  #       environment.TZ = "Europe/Berlin";
  #       # Note: The image will not be updated on rebuilds, unless the version label changes
  #       image = "ghcr.io/home-assistant/home-assistant:stable";
  #       extraOptions = [
  #         # Use the host network namespace for all sockets
  #         "--network=host"
  #       ];
  #     };
  #   };
  # };

  # Disable systemd targets for sleep and hibernation
  systemd = {
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  system.stateVersion = "24.05";
}
