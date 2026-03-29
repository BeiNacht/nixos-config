{
  config,
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  imports = [
    ../configs/common.nix
    ../configs/develop.nix
  ];

  system = {
    primaryUser = "alex";
    defaults = {
      dock = {
        autohide = true;
        expose-animation-duration = 0.0;
        mru-spaces = false;
        orientation = "left";
        show-recents = false;
      };
      finder = {
        _FXSortFoldersFirst = true;
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      screencapture.location = "~/Pictures/screenshots";
      #   screensaver.askForPasswordDelay = 10;

      # AutoFillCreditCardData = false;  # Enable AutoFill for credit cards
      # AutoFillPasswords = false; # Enable AutoFill for passwords
    };
  };

  # services = {
  #   nix-daemon.enable = true;
  # };

  nix.settings.experimental-features = "nix-command flakes";

  nix = {
    enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      # mactop
      nh
      mas
    ];
  };

  # programs = {
  #   nh = {
  #     enable = true;
  # clean = {
  #   enable = true;
  #   extraArgs = "--keep-since 14d";
  # };
  # flake = "/User/alex/nixos-config";
  #   };
  # };

  homebrew = {
    enable = true;
    brews = [
      "gstreamer"
      "virt-manager"
      "virt-viewer"
      "rom-tools"
    ];
    casks = [
      "adobe-acrobat-reader"
      "alt-tab"
      "android-file-transfer"
      "appcleaner"
      "bit-slicer"
      "brave-browser"
      "cog-app"
      "crossover"
      "deskflow"
      "discord"
      "sozercan/repo/kaset"
      "docker-desktop"
      "easy-move+resize"
      "firefox"
      "font-meslo-lg-nerd-font"
      "font-roboto-mono-nerd-font"
      "font-sauce-code-pro-nerd-font"
      "font-sf-mono-nerd-font-ligaturized"
      # "ghostty"
      "handbrake-app"
      "iina"
      "iterm2"
      "keepassxc"
      "keepingyouawake"
      "lulu"
      "macfuse"
      "macpacker"
      "microsoft-auto-update"
      "microsoft-teams"
      "middleclick"
      "monero-wallet"
      "nextcloud"
      "only-switch"
      "pcsx2"
      "rectangle"
      "signal"
      "steam"
      "tailscale-app"
      "tor-browser"
      "visual-studio-code"
      "vorta"
      "pear-devs/pear/pear-desktop"
    ];
    taps = [
      "mhaeuser/mhaeuser"
      "deskflow/homebrew-tap"
      "jeffreywildman/homebrew-virt-manager"
    ];
  };
  system.stateVersion = 5;
}
