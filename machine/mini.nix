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

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };

    extraModulePackages = with pkgs.linuxPackages; [ rtl88x2bu ];
  };

  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = { enable = false; };
    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp0s20u1u1.useDHCP = true;
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.3/24" ];
        privateKey = secrets.wireguard-mini-private;

        peers = [{
          publicKey = secrets.wireguard-vps-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "207.180.220.97:51820";
          persistentKeepalive = 25;
        }];

        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
        '';

        # This undoes the above command
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
        '';
      };
    };

    nat = {
      enable = true;
      externalInterface = "wlp0s20u1u1";
      internalInterfaces = [ "wg0" ];
    };

    wireless = {
      enable = true;
      networks.Skynet.psk = secrets.wifipassword;
      interfaces = [ "wlp0s20u1u1" ];
    };
  };

  # nixpkgs.config.packageOverrides = pkgs: {
  #   vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  # };
  # hardware.opengl = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-media-driver # LIBVA_DRIVER_NAME=iHD
  #     vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
  #     vaapiVdpau
  #     libvdpau-va-gl
  #   ];
  # };

  services = {
    # k3s = {
    #   enable = true;
    #   role = "server";
    # };

    ddclient = {
      enable = true;
      verbose = true;
      server = "dyndns.strato.com/nic/update";
      username = "beinacht.org";
      passwordFile = "/home/alex/nixos-config/ddclient.conf";
      domains = [ "home.beinacht.org" ];
    };

    # printing = {
    #   enable = true;
    #   drivers = [ pkgs.brlaser ];
    #   browsing = true;
    #   listenAddresses = [
    #     "*:631"
    #   ]; # Not 100% sure this is needed and you might want to restrict to the local network
    #   allowFrom = [
    #     "all"
    #   ]; # this gives access to anyone on the interface you might want to limit it see the official documentation
    #   defaultShared = true; # If you want
    # };

    # avahi = {
    #   enable = true;
    #   publish.enable = true;
    #   publish.userServices = true;
    # };

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs =
        "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH =
        "ssh -o StrictHostKeyChecking=no -i /home/alex/.ssh/id_ed25519";
      paths = [ "/home/alex" "/var/lib" ];
      repo = secrets.borg-repo;
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = [ "/home/alex/.cache" ];
    };

  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "23.11";
}
