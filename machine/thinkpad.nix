{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
     ./thinkpad/hardware-configuration.nix
    # ../../configs/borg.nix
    ../configs/common-linux.nix
    ../configs/develop.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    ../configs/games.nix
    ../configs/plasma-desktop.nix
    ../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-thinkpad.yaml;
    # KEY=value env file consumed by networkmanager.ensureProfiles below.
    secrets.wifi-env = {};
  };

  boot = {
    kernelModules = ["kvm-intel"];
    initrd = {
      availableKernelModules = ["xhci_pci" "nvme" "usb_storage" "sd_mod"];
      kernelModules = ["dm-snapshot"];
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/7f2eb00d-49d8-416f-a742-5af5ce871483";
          preLVM = true;
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # extraModulePackages = with pkgs.linuxPackages_latest; [rtl88x2bu];
  };

  networking = {
    hostName = "thinkpad";
    firewall = {enable = false;};
    # interfaces = {
    #   br0 = {
    #     useDHCP = true;
    #   };
    # };

    # bridges.br0.interfaces = ["enp3s0"];

    nftables.enable = true;

    # Wi-Fi is managed by NetworkManager (pulled in by plasma-desktop.nix ->
    # user-gui.nix) rather than wpa_supplicant now, since the two backends
    # can't coexist. This profile reproduces the same auto-connect network.
    networkmanager.ensureProfiles.environmentFiles = [config.sops.secrets.wifi-env.path];
    networkmanager.ensureProfiles.profiles."Skynet-mobil" = {
      connection = {
        id = "Skynet-mobil";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "Skynet-mobil";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$SKYNET_MOBIL_PSK";
      };
    };
  };

  hardware = {
    enableAllFirmware = true;

    cpu.intel.updateMicrocode = true;

    graphics.enable = true;

    # Hybrid Intel UHD 630 / NVIDIA GTX 1050 Ti Mobile graphics. Use PRIME
    # render offload so the Intel iGPU stays the primary display driver
    # (battery life) and individual apps/games run on the NVIDIA GPU on
    # demand via the `nvidia-offload` wrapper (see games launched from
    # Lutris/Steam: set "nvidia-offload" as the command prefix).
    nvidia = {
      modesetting.enable = true;
      open = false; # Pascal (GP107) isn't supported by the open kernel module
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  services = {
    xserver.videoDrivers = ["nvidia"];

    locate = {
      prunePaths = ["/mnt" "/nix"];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "24.11";
}
