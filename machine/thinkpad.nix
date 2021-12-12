{ config, pkgs, lib, ... }:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
  secrets-thinkpad = import ../configs/secrets-thinkpad.nix;
  be = import ../configs/borg-exclude.nix;
in
{
  nixpkgs.config = {
    allowUnfree = true;
  };
  imports =
    [
      <nixos-hardware/lenovo/thinkpad/x1-extreme>
      /etc/nixos/hardware-configuration.nix
      ../configs/gui.nix
      ../configs/docker.nix
      ../configs/libvirt.nix
      ../configs/common.nix
      ../configs/user.nix
      ../configs/user-gui.nix
      ../configs/user-gui-applications.nix
      ../configs/bspwm.nix
      # ../configs/pantheon.nix
      <home-manager/nixos>
    ];

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;
        gfxmodeEfi = "1024x768";
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    kernelPackages = pkgs.linuxPackages_5_14;
    plymouth.enable = true;
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-uuid/9e93feb7-8134-4b62-a05b-1aeade759880";
        keyFile = "/keyfile0.bin";
        allowDiscards = true;
      };
      secrets = {
        "keyfile0.bin" = "/etc/secrets/initrd/keyfile0.bin";
        "keyfile1.bin" = "/etc/secrets/initrd/keyfile1.bin";
      };
    };
  };

  # Data mount
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/33693f43-076d-41fc-a612-f49ab6870ccb"; # UUID for /dev/mapper/crypted-data
    encrypted = {
      enable = true;
      label = "crypted-data";
      blkDev = "/dev/disk/by-uuid/9bf1d00e-1edc-4de3-9d5e-71a6722ef193"; # UUID for /dev/sda1
      keyFile = "/keyfile1.bin";
    };
  };

  networking.hostName = "thinkpad"; # Define your hostname.
  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "latarcyrheb-sun32";
    keyMap = "us";
  };

  hardware.nvidia.prime = {
    offload.enable = true;

    # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
    intelBusId = "PCI:0:2:0";

    # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
    nvidiaBusId = "PCI:1:0:0";
  };

  #  hardware.bumblebee = {
  #    enable = true;
  #    connectDisplay = true;
  #  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  nixpkgs.config.packageOverrides = pkgs: rec {
    #    bumblebee = pkgs.bumblebee.override {
    #      extraNvidiaDeviceOptions = ''
    #        Option "ProbeAllGpus" "false"
    #        Option "AllowEmptyInitialConfiguration"
    #      EndSection#

    #      Section "ServerLayout"
    #        Identifier  "Layout0"
    #        Option      "AutoAddDevices" "true"     # Bumblebee defaults to false
    #        Option      "AutoAddGPU" "false"
    #      EndSection

    #      Section "Screen"                            # Add this section
    #        Identifier "Screen0"
    #        Device "DiscreteNvidia"
    #      '';
    #    };
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    daemon = {
      config = {
        avoid-resampling = "yes";
      };
    };
    configFile = pkgs.runCommand "default.pa" { } ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
        ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
    '';
  };
  hardware.sane.enable = true;

  services = {
    thinkfan = {
      enable = true;
      levels = [
        [ 0 0 67 ]
        [ 1 65 75 ]
        [ 2 73 80 ]
        [ 3 78 85 ]
        [ 4 83 90 ]
        [ 6 88 95 ]
        [ 7 93 32767 ]
      ];
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
      # deviceSection = ''BusID "PCI:0:2:0"'';
      # deviceSection = ''
      # Option "TearFree" "true"
      # '';
    };
    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;
    # tlp = {
    #   enable = true;
    #   settings = {
    #     START_CHARGE_THRESH_BAT0 = 80;
    #     STOP_CHARGE_THRESH_BAT0 = 90;
    #   };
    # };
    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets-thinkpad.borg-key;
      };
      extraCreateArgs = "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = secrets-thinkpad.borg-repo;
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  home-manager.users.alex.services.barrier.client = {
    enable = true;
    enableCrypto = false;
    name = "thinkpad";
    server = "192.168.0.150:24800";
  };

  environment.systemPackages = with pkgs; [
    nvidia-offload
    # xorg.xf86videointel
    intel-gpu-tools
  ];

  networking.firewall.enable = false;

  powerManagement.powertop.enable = true;

  system.stateVersion = "21.05";
}
