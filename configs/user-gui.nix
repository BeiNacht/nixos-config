{
  config,
  pkgs,
  inputs,
  home-manager,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];
  networking = {
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      nerd-fonts.meslo-lg
      nerd-fonts.roboto-mono
      corefonts

      # google-fonts

      liberation_ttf

      libertinus

      gyre-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-extra
      open-sans
      stix-two
      twemoji-color-font
    ];
  };

  programs = {
    ssh = {startAgent = true;};
    # dconf.enable = true;
    # gnupg.agent = {
    #   enable = true;
    #   pinentryFlavor = "curses";
    #   # enableSSHSupport = true;
    # };
  };

  environment = {
    systemPackages = with pkgs; [
      czkawka # fslint before
      handbrake
      keepassxc
      nextcloud-client
      pinta
      simple-scan

      # discord
      kdePackages.kdenlive
      # shotcut

      telegram-desktop
      signal-desktop

      vorta
      kitty

      libreoffice
    ];
    persistence."/persist" = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
  };

  home-manager.users.alex = {pkgs, ...}: {
    programs = {
      vscode = {
        enable = true;
        package = pkgs.vscode;
      };

      mpv = {
        enable = true;
        config = {
          hwdec = "auto-safe";
          vo = "gpu";
          profile = "gpu-hq";
        };
      };

      # kitty = {
      #   enable = true;
      #   extraConfig = ''
      #     enable_audio_bell false

      #     background            #000000
      #     foreground            #e9e9e9
      #     cursor                #e9e9e9
      #     selection_background  #424242
      #     color0                #000000
      #     color8                #555555
      #     color1                #d44d53
      #     color9                #d44d53
      #     color2                #b9c949
      #     color10               #b9c949
      #     color3                #e6c446
      #     color11               #e6c446
      #     color4                #79a6da
      #     color12               #79a6da
      #     color5                #c396d7
      #     color13               #c396d7
      #     color6                #70c0b1
      #     color14               #70c0b1
      #     color7                #fffefe
      #     color15               #fffefe
      #     selection_foreground  #000000
      #   '';
      # };
    };
  };
}
