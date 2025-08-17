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
      "deskflow"
      "discord"
      "firefox"
      "font-meslo-lg-nerd-font"
      "iina"
      "iterm2"
      "keepassxc"
      "macfuse"
      "microsoft-teams"
      "middleclick"
      "easy-move+resize"
      "nextcloud"
      "rectangle"
      "sol"
      "steam"
      "tailscale"
      "tor-browser"
      "visual-studio-code"
      "vorta"
    ];
    taps = [
      "mhaeuser/mhaeuser"
      "deskflow/homebrew-tap"
    ];
  };
  system.stateVersion = 5;
}
