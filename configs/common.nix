{ config, pkgs, lib, ... }:

{
  imports =
    [
      (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
    ];

  services.vscode-server.enable = true;

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      customPkgs = [
        pkgs.zsh-autosuggestions
        pkgs.zsh-syntax-highlighting
        pkgs.zsh-powerlevel10k
      ];
      plugins = [
        "cp"
        "common-aliases"
        "docker "
        "systemd"
        "wd"
        "kubectl"
        "git"
        # "zsh-autosuggestions"
        # "zsh-syntax-highlightin"
      ];
    };
  };

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
    gocryptfs
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
    wget
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
