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

  # Build btop with the driver runpath so it can dlopen libnvidia-ml and
  # show NVIDIA GPU usage.
  nixpkgs.overlays = [
    (final: prev: {btop = prev.btop.override {cudaSupport = true;};})
  ];

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
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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

    # Quieter fan curve than the EC's "auto" mode, which spins both fans up
    # to ~4400 RPM already at ~70°C. Letting the CPU sit in the high 70s is
    # fine; the EC takes back over (level auto) above 82°C as a safety net.
    # Sensors default to /proc/acpi/ibm/thermal (max of CPU and GPU).
    thinkfan = {
      enable = true;
      levels = [
        [0 0 55]
        [1 50 64]
        [2 60 70]
        [3 66 74]
        [4 71 77]
        [5 74 80]
        [7 77 84]
        ["level auto" 82 32767]
      ];
    };

    # Cap CPU package power (stock firmware limits are PL1 55 W / PL2 78 W)
    # so sustained load produces less heat for the fans to deal with.
    # throttled re-applies the limits periodically, since the X1 Extreme
    # firmware resets them (e.g. on AC plug/unplug or resume).
    throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True

        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 25
        PL1_Duration_s: 28
        PL2_Tdp_W: 35
        PL2_Duration_S: 0.002
        Trip_Temp_C: 85
        cTDP: 0
        Disable_BDPROCHOT: False

        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 35
        PL1_Duration_s: 28
        PL2_Tdp_W: 45
        PL2_Duration_S: 0.002
        Trip_Temp_C: 90
        cTDP: 0
        Disable_BDPROCHOT: False
      '';
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "24.11";
}
