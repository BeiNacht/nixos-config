# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
  secrets = import ../configs/secrets.nix;
in
{
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
      <home-manager/nixos>
    ];

  # boot.initrd.luks.devices = {
	# root = {
	# 	preLVM = true;
 	# 	device = "/dev/disk/by-uuid/b59e9746-b9b4-4de1-94f6-84a387b9d72e";
	# 	allowDiscards = true;
  # 	};
  # };

  fileSystems."/".options = [ "noatime" "discard" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.gfxmodeEfi = "1024x768";

  # boot.plymouth.enable = true;

  # environment.etc."issue.d/ip.issue".text = "\\4\n";

  networking.hostName = "thinkpad"; # Define your hostname.

  # Set your time zone.
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
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
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
    configFile = pkgs.runCommand "default.pa" {} ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
        ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
    '';
  };
  hardware.sane.enable = true;

  #thinkfan
  services.thinkfan = {
    enable = true;
    levels = [
      [0 0 67]
      [1 65 75]
      [2 73 80]
      [3 78 85]
      [4 83 90]
      [6 88 95]
      [7 93 32767]
    ];
  };
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
      # deviceSection = ''BusID "PCI:0:2:0"'';
    };
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 80;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };
    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2" ;
        passphrase = secrets.borg-desktop-key;
      };
      extraCreateArgs = "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = "ssh://szczepan.ski/~/borg-backup/thinkpad";
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) [
        ".config/chromium/Default/Service Worker/CacheStorage"
        ".cache"
        ".local/share/libvirt/images"
        ".local/share/Steam/steamapps"
        "Games/guild-wars/drive_c/Program Files/Guild Wars/Gw.dat"
        "Games/guild-wars-second/drive_c/Program Files/Guild Wars/Gw.dat"
        "Kamera"
        "Nextcloud"
        "Sync"
        "Workspace"
      ];
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
    xorg.xf86videointel
    intel-gpu-tools
    gnome.simple-scan
  ];

  networking.firewall.enable = false;

  system.stateVersion = "21.05";
}
