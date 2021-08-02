{ config, pkgs, lib, ... }:

{
  imports =
    [
      (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
    ];

  environment.shells = with pkgs; [ bashInteractive zsh ];

  services = {
    vscode-server.enable = true;
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      openFirewall = true;
    };
    nextdns = {
      enable = true;
      arguments = [
        "-config"
        "aaa56c"
        "-cache-size"
        "10MB"
        "-listen"
        "127.0.0.1:53"
        "-report-client-info"
      ];
    };
    fwupd.enable = true;
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
  };

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
    unzip
    zsh
    neofetch
    cargo
    youtube-dl
    git-secrets
    gnupg
    nmap
  ];

  documentation.enable = false;

  nix.autoOptimiseStore = true;

  boot = {
    tmpOnTmpfs = true;
    kernelParams = [ "quiet" ];
    consoleLogLevel = 0;
    kernel.sysctl = {
      "vm.max_map_count" = 262144;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
