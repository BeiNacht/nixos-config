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
    inxi
    iotop
    lm_sensors
    lsof
    manpages
    ncdu
    nodejs
    pciutils
    pstree
    ruby
    sshfs
    tealdeer
    tree
    usbutils
    zsh
  ];

  documentation.enable = false;
  documentation.nixos.enable = false;
  #documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  nix.autoOptimiseStore = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
