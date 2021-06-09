{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kitty
    chromium
    gparted
    keepassxc
    meld
    twemoji-color-font
    mpv
    brave
    firefox
    alacritty
    baobab
    lutris
    insomnia
    jellyfin-web
    kdenlive
    nextcloud-client
    barrier
    solaar
    spotify
    vulkan-tools
    gnome.eog
    virtmanager
  ];
}
