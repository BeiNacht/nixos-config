{ config, pkgs, lib, ... }:

{
  boot.tmpOnTmpfs = true;
  environment.systemPackages = with pkgs; [
    ack
    atop
    dfc
    git
    lsof
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

  documentation.enable = false;
  documentation.nixos.enable = false;
  #documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
}
