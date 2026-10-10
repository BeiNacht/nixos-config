{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: let
  shares = import ../configs/samba-shares.nix;
in {
  imports = [
    # ../configs/borg.nix
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    ../configs/lan-server.nix
    ../configs/plasma-desktop.nix
    ../configs/games.nix
    ../configs/samba.nix
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
    interfaces = {
      enp1s0.useDHCP = true;
    };
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

    # unifi = {
    #   enable = true;
    #   unifiPackage = pkgs.unifi;
    #   mongodbPackage = pkgs.mongodb-ce;
    # };

    samba = {
      settings = {
        storage = shares.share "/home/alex/homeserver/storage";
        homeassistant = shares.share "/home/alex/homeserver/storage/homeassistant";
        timemachine = shares.timeMachine "/home/alex/homeserver/storage/timemachine";
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
