{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    ack
    dfc
    git
    glances
    home-manager
    htop
    ncdu
    zsh
    ruby
    pstree
    pciutils
    borgbackup
    bpytop
    broot
    bwm_ng
    nodejs
    sshfs
    tealdeer
    tree
    lm_sensors
  ];
}
