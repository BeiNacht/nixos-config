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

    stateVersion = 5;
  };

  # services = {
  #   nix-daemon.enable = true;
  # };

  nix.settings.experimental-features = "nix-command flakes";

  nix = {
    enable = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

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
    enableZshIntegration = true;
    brews = [
      "borgbackup"
      "hf"
      # "joshavant/tap/clawbox"
      "llama.cpp"
      "mactop"
      "qwen-code"
      "hermes-agent"
      "node"
      "oven-sh/bun/bun"
      "rom-tools"
      "westpoint-io/dustoff/dustoff"
      "nohajc/anylinuxfs/anylinuxfs"
    ];
    casks = [
      "alt-tab"
      "android-file-transfer"
      "appcleaner"
      "betterdisplay"
      "bit-slicer"
      "brave-browser"
      "claude-code"
      "cog-app"
      "crossover"
      "deskflow/tap/deskflow"
      "discord"
      "docker-desktop"
      "fenio/tap/anylinuxfs-gui"
      "firefox"
      "font-meslo-lg-nerd-font"
      "font-roboto-mono-nerd-font"
      "font-sauce-code-pro-nerd-font"
      "font-sf-mono-nerd-font-ligaturized"
      "handbrake-app"
      "heroic"
      "iina"
      "iterm2"
      "keepassxc"
      "keepingyouawake"
      "lm-studio"
      "lulu"
      "macfuse"
      "macpacker"
      "microsoft-auto-update"
      "microsoft-teams"
      "monero-wallet"
      "nextcloud"
      "pcsx2"
      "pear-devs/pear/pear-desktop"
      "rectangle"
      "signal"
      "sol"
      "sozercan/repo/kaset"
      "steam"
      "tailscale-app"
      "telegram-desktop"
      "tor-browser"
      "visual-studio-code"
      "vorta"
    ];
    onActivation = {
      cleanup = "zap";
      # cleanup = "check";
      autoUpdate = true;
      upgrade = true;
      extraFlags = [
        "--verbose"
      ];
    };
  };
}
