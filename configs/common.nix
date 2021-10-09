{ config, pkgs, lib, ... }:
let
  secrets = import ./secrets.nix;
in
{
  environment.shells = with pkgs; [ bashInteractive zsh ];

  services = {
    vnstat.enable = true;
    tuptime.enable = true;
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      openFirewall = true;
      extraConfig = "StreamLocalBindUnlink yes";
    };
    nextdns = {
      enable = true;
      arguments = [
        "-config" secrets.nextdnshash
        "-cache-size" "10MB"
        "-listen" "127.0.0.1:53"
        "-forwarder" secrets.nextdnsforwarder
        "-report-client-info"
      ];
    };
    fwupd.enable = true;
    journald = {
      extraConfig = "SystemMaxUse=500M";
    };
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    hosts = {
      "2.56.97.114" = ["szczepan.ski"];
      "10.100.0.1" = ["vps.wg"];
      "10.100.0.2" = ["desktop.wg"];
      "10.100.0.3" = ["mini.wg"];
      "192.168.0.24" = ["mini.lan"];
      "192.168.0.100" = ["homeserver.lan"];
      "192.168.0.150" = ["desktop.lan"];
    };
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  environment.systemPackages = with pkgs; [
    ack
    borgbackup
    broot
    btrfs-progs
    bwm_ng
    cargo
    exa
    ffmpeg
    gnupg
    gocryptfs
    graphviz
    hdparm
    home-manager
    inxi
    iotop
    lm_sensors
    lsd
    lsof
    manpages
    nix-du
    nix-tree
    nmap
    nodejs
    parallel
    pciutils
    ruby
    tealdeer
    unixtools.xxd
    unzip
    usbutils
    wget
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
