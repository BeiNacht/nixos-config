{ config, pkgs, ... }:
let secrets = import ../configs/secrets.nix;
in {
  imports = [
    <nixos-hardware/common/cpu/intel>
    /etc/nixos/hardware-configuration.nix
    ../configs/docker.nix
    ../configs/libvirt.nix
    ../configs/common.nix
    ../configs/user.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = with pkgs.linuxPackages; [ rtl88x2bu ];

  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = { enable = false; };
    networkmanager.enable = true;
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.3/24" ];
        privateKey = secrets.wireguard-mini-private;

        peers = [{
          publicKey = secrets.wireguard-vps-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "szczepan.ski:51820";
          persistentKeepalive = 25;
        }];
      };
    };
  };

  services = {
    # k3s = {
    #   enable = true;
    #   role = "server";
    # };

    # nextdns = {
    #   arguments = pkgs.lib.mkForce [
    #     "-config"
    #     secrets.nextdnshash
    #     "-cache-size"
    #     "10MB"
    #     "-listen"
    #     "0.0.0.0:53"
    #     "-listen"
    #     ":::53"
    #     "-forwarder"
    #     secrets.nextdnsforwarder
    #     "-report-client-info"
    #   ];
    # };

    ddclient = {
      enable = true;
      verbose = true;
      server = "dyndns.strato.com/nic/update";
      username = "beinacht.org";
      passwordFile = "/home/alex/nixos-config/ddclient.conf";
      domains = [ "home.beinacht.org" ];
    };

    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
      browsing = true;
      listenAddresses = [
        "*:631"
      ]; # Not 100% sure this is needed and you might want to restrict to the local network
      allowFrom = [
        "all"
      ]; # this gives access to anyone on the interface you might want to limit it see the official documentation
      defaultShared = true; # If you want
    };

    avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };

  };

  system.stateVersion = "23.05";
}
