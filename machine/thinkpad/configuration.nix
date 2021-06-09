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
in
{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/thinkpad/x1-extreme>
      /etc/nixos/hardware-configuration.nix
      ../../configs/gui.nix
      ../../configs/virtualisation.nix
      ../../configs/common.nix
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

  boot.tmpOnTmpfs = true;
  #boot.plymouth.enable = true;
  
  environment.etc."issue.d/ip.issue".text = "\\4\n";

  networking.hostName = "thinkpad"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
     font = "latarcyrheb-sun32";
     keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.desktopManager.pantheon.enable = true;
  services.xserver.desktopManager.pantheon.extraWingpanelIndicators = [ pkgs.pantheon.wingpanel-indicator-nightlight ];
  #services.xserver.dpi = 144;

  services.xserver = {
    videoDrivers = [ "nvidia" ];
#    deviceSection = ''BusID "PCI:0:2:0"'';
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

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  fonts.fonts = with pkgs; [
    open-sans
    roboto-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts
    dina-font
    proggyfonts
  ];
 
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

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

  #nextdns
  services.nextdns = {
    enable = true;
    arguments = [
      "-config"
      "aaa56c"
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" ];
    };
  };
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=WebUIDarkMode,NativeNotifications,VaapiVideoDecoder --ignore-gpu-blocklist --use-gl=desktop --force-dark-mode --disk-cache-dir=/tmp/cache";
  programs.chromium = {
    enable = true;
    extensions = [
      "cbnipbdpgcncaghphljjicfgmkonflee" # Axel Springer Blocker
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
      "gcbommkclmclpchllfjekcdonpmejbdp" # HTTPS Everywhere
      "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
      "fploionmjgeclbkemipmkogoaohcdbig" # Page load time
      "egnjhciaieeiiohknchakcodbpgjnchh" # Tab Wrangler
      "fnaicdffflnofjppbagibeoednhnbjhg" # Floccus bookmarks
    ];
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "AutofillAddressEnabled" = true;
      "AutofillCreditCardEnabled" = false;
      "BuiltInDnsClientEnabled" = false;
      "MetricsReportingEnabled" = true;
      "SearchSuggestEnabled" = false;
      "AlternateErrorPagesEnabled" = false;
      "UrlKeyedAnonymizedDataCollectionEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
                               "de"
                               "en-US"
                             ];
      "CloudPrintSubmitEnabled" = false;
    };
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "cp"
        "common-aliases"
        "docker "
        "systemd"
        "wd"
        "kubectl"
#        "zsh-autosuggestions"
#        "zsh-syntax-highlightin"
        "git"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    nvidia-offload
    xorg.xf86videointel
    intel-gpu-tools
    steam
    vscode
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 52698 ];
  networking.firewall.allowedUDPPorts = [ 52698 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}

