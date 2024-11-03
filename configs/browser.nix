{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    brave
    librewolf
    tor-browser-bundle-bin
  ];
}
