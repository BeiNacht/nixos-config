{ config, pkgs, lib, ... }:

{
  boot.tmpOnTmpfs = true;
  environment.systemPackages = with pkgs; [
    ack
    atop
    borgbackup
    bpytop
    broot
    btrfs-progs
    bwm_ng
    dfc
    git
    glances
    home-manager
    htop
    iotop
    lm_sensors
    lsof
    ncdu
    nodejs
    pciutils
    pstree
    ruby
    sshfs
    tealdeer
    tree
    zsh
  ];

  documentation.enable = false;
  documentation.nixos.enable = false;
  #documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
}
