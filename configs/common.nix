{ config, pkgs, lib, ... }:
let secrets = import ./secrets.nix;
in {
  environment.shells = with pkgs; [ bashInteractive zsh ];

  services = {
    vnstat.enable = true;
    tuptime.enable = true;
    locate.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      openFirewall = true;
      extraConfig = "StreamLocalBindUnlink yes";
    };
    nextdns = {
      enable = true;
      arguments = [
        "-config"
        secrets.nextdnshash
        "-cache-size"
        "10MB"
        "-listen"
        "127.0.0.1:53"
        "-report-client-info"
      ];
    };
    fwupd.enable = true;
    journald = { extraConfig = "SystemMaxUse=500M"; };
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    hosts = {
      "207.180.220.97" = [ "szczepan.ski" ];
      "10.100.0.1" = [ "vps.wg" ];
      "10.100.0.2" = [ "desktop.wg" ];
      "10.100.0.3" = [ "mini.wg" ];
    };
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
  };

  environment.systemPackages = with pkgs; [
    ack
    borgbackup
    borgmatic
    btrfs-progs
    cargo
    dog
    du-dust
    duf
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
    man-pages
    nethogs
    nil
    nix-du
    nix-tree
    nixpkgs-fmt
    nmap
    nodejs
    parallel
    pciutils
    ruby
    unixtools.xxd
    unzip
    usbutils
    wget
  ];

  documentation.enable = false;

  nix.settings = { auto-optimise-store = true; };

  boot = {
    tmp.useTmpfs = true;
    kernelParams = [ "quiet" ];
    consoleLogLevel = 0;
    kernel.sysctl = { "vm.max_map_count" = 262144; };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
