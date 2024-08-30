{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> {};
in
{
  environment.shells = with pkgs; [ bashInteractive zsh ];

  programs = {
    nh = {
      enable = true;
      # clean = {
      #   enable = true;
      #   extraArgs = "--keep-since 14d --keep 5";
      # };
    };
  };

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

    dnscrypt-proxy2 = {
      enable = true;
      settings = {
        ipv6_servers = true;
        require_dnssec = true;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };

        # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        # server_names = [ ... ];
      };
    };

    journald = { extraConfig = "SystemMaxUse=500M"; };
  };

  networking = {
    nameservers = [ "127.0.0.1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
  };

  environment.systemPackages = with unstable.pkgs; [
    ack
    borgbackup
    borgmatic

    btrfs-progs

    cargo
    # dog # different cat
    doggo # DNS Resolver

    du-dust
    ncdu

    duf
    dfc

    eza

    btop
    htop
    glances

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
    man-pages-posix
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
    progress
    unixtools.xxd
    unzip
    usbutils
    wget
  ];

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  boot = {
    tmp.useTmpfs = false;
    kernelParams = [ "quiet" ];
    consoleLogLevel = 0;
    kernel.sysctl = { "vm.max_map_count" = 262144; };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
