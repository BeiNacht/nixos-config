{ config, pkgs, inputs, outputs, ... }:
let secrets = import ../../configs/secrets.nix;
in {

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    ../../configs/docker.nix
    ../../configs/common.nix
    ../../configs/user.nix
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
    interfaces = {
      enp3s0.useDHCP = true;
      # wlp0s20u1u1.useDHCP = true;
      wlp0s20u1u2.ipv4.addresses = [{ address = "192.168.12.1"; prefixLength = 24; }];
    };

    nftables.enable = true;
    # wireguard.interfaces = {
    #   wg0 = {
    #     ips = [ "10.100.0.3/24" ];
    #     privateKey = secrets.wireguard-mini-private;

    #     peers = [{
    #       publicKey = secrets.wireguard-vps-public;
    #       presharedKey = secrets.wireguard-preshared;
    #       allowedIPs = [ "10.100.0.0/24" ];
    #       endpoint = "[2a02:c207:3008:1547::1]:51820";
    #       persistentKeepalive = 25;
    #     }];

    #     postSetup = ''
    #       ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
    #     '';

    #     # This undoes the above command
    #     postShutdown = ''
    #       ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o enp3s0 -j MASQUERADE
    #     '';
    #   };
    # };

    # nat = {
    #   enable = true;
    #   enableIPv6 = true;
    #   # externalInterface = "enp3s0";
    #   # internalInterfaces = [ "tailscale0" ];
    # };

    # wireless = {
    #   enable = true;
    #   networks.Skynet.psk = secrets.wifipassword;
    #   interfaces = [ "wlp0s20u1u1" ];
    # };

  };

  environment.systemPackages = with pkgs; [
    nyx
  ];

  services = {
    tor = {
      enable = true;
      # openFirewall = true;
    };

    hostapd = {
      enable = true;
      radios = {
        wlp0s20u1u2 = {
          # wifi4.enable = false;
          # wifi5.enable = false;
          # settings.ieee80211n = true; # otherwise enabled by wifi4.enable
          networks.wlp0s20u1u2 = {
            ssid = "Skynet-Tor";
            authentication.saePasswords = [
              { password = "REMOVED_OLD_PASSWORD_FROM_HISTORY"; }
            ];
          };

        };
      };
    };

    # dnsmasq = {
    #   enable = true;
    #   extraConfig = ''
    #     interface=wlp0s20u1u2
    #     bind-interfaces
    #     dhcp-range=192.168.12.10,192.168.12.254,24h
    #   '';
    # };

    kea.dhcp4 = {
      enable = true;
      # interfaces = [ "wlp0s20u1u2" ];
      settings = {
        interfaces-config = {
          interfaces = [
            "wlp0s20u1u2"
          ];
        };
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        rebind-timer = 2000;
        renew-timer = 1000;
        subnet4 = [
          {
            pools = [
              {
                pool = "192.168.12.100 - 192.168.12.240";
              }
            ];
            subnet = "192.168.12.0/24";
          }
        ];
        valid-lifetime = 4000;
      };
    };

    haveged.enable = true;

    # k3s = {
    #   enable = true;
    #   role = "server";
    # };

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

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = "--advertise-exit-node --login-server=https://headscale.szczepan.ski";
    };

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
    # cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "24.05";
}
