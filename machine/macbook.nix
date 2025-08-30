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
      mactop
      nh
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
    casks = [
      "alt-tab"
      "appcleaner"
      "battery-toolkit"
      "brave-browser"
      "cog-app"
      "comfyui"
      "crossover"
      "deskflow"
      "discord"
      "docker-desktop"
      "easy-move+resize"
      "firefox"
      "font-meslo-lg-nerd-font"
      "font-roboto-mono-nerd-font"
      "font-sauce-code-pro-nerd-font"
      "font-sf-mono-nerd-font-ligaturized"
      "ghostty"
      "handbrake-app"
      "iina"
      "iterm2"
      "jordanbaird-ice"
      "keepassxc"
      "keepingyouawake"
      "macfuse"
      "microsoft-teams"
      "middleclick"
      "nextcloud"
      "only-switch"
      "pcsx2"
      "rectangle"
      "sol"
      "spotify"
      "steam"
      "tailscale-app"
      "tor-browser"
      "visual-studio-code"
      "vorta"
      "warp"
      "utm"
      "whisky"
    ];
    taps = [
      "mhaeuser/mhaeuser"
      "deskflow/homebrew-tap"
    ];
  };
  system.stateVersion = 5;
}
