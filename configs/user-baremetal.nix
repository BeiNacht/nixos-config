{
  config,
  pkgs,
  inputs,
  home-manager,
  ...
}: {
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      (nerdfonts.override {fonts = ["Meslo" "RobotoMono"];})

      corefonts

      google-fonts

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

  environment.systemPackages = with pkgs; [
    czkawka # fslint before
    grsync
    handbrake
    keepassxc
    nextcloud-client
    pinta
    rustdesk-flutter
    simple-scan
    telegram-desktop
    discord
    kdenlive
    shotcut
  ];
}
