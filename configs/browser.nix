{ config, pkgs, lib, ... }:
{
  programs.firefox = {
    enable = true;
    # nativeMessagingHosts.packages = with pkgs; [ uget-integrator ];
  };

  environment.systemPackages = with pkgs; [
    # uget
    brave
    librewolf
    tor-browser-bundle-bin
  ];
}
