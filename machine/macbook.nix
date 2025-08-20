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

  homebrew = {
    enable = true;
    casks = [
      "alt-tab"
      "battery-toolkit"
      "brave-browser"
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
      "iina"
      "iterm2"
      "keepassxc"
      "macfuse"
      "microsoft-teams"
      "middleclick"
      "nextcloud"
      "pcsx2"
      "rectangle"
      "sol"
      "steam"
      "tailscale"
      "tor-browser"
      "visual-studio-code"
      "vorta"
      "whisky"
    ];
    taps = [
      "mhaeuser/mhaeuser"
      "deskflow/homebrew-tap"
    ];
  };
  system.stateVersion = 5;
}
