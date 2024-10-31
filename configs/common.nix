{ config, pkgs, lib, ... }:
{
  boot = {
    tmp = {
      useTmpfs = lib.mkDefault true;
      cleanOnBoot = true;
    };
    # kernelParams = [ "quiet" ];
    consoleLogLevel = 0;
    kernel.sysctl = { "vm.max_map_count" = 262144; };
    initrd.systemd.enable = (!config.boot.swraid.enable && !config.boot.isContainer);
  };

  # Work around for https://github.com/NixOS/nixpkgs/issues/124215
  documentation.info.enable = false;

  environment = {
    # Don't install the /lib/ld-linux.so.2 stub. This saves one instance of nixpkgs.
    ldso32 = null;

    shells = with pkgs; [ bashInteractive zsh ];

    systemPackages = with pkgs; [
      ack
      borgbackup
      borgmatic

      btrfs-progs
      exfatprogs

      # dog # cat replace
      doggo # DNS Resolver

      du-dust
      ncdu
      duf # dfc alternative
      lsd # eza alternative

      # age key encryption
      ssh-to-age
      age
      sops

      # monitoring
      btop
      htop
      glances
      nethogs
      iotop
      nmap
      nmon
      bandwhich

      gnupg
      gocryptfs
      graphviz
      hdparm
      inxi
      lm_sensors
      lsof
      man-pages
      man-pages-posix
      kitty.terminfo

      nil
      nix-du
      nix-tree
      nixpkgs-fmt

      parallel
      pciutils
      progress
      unixtools.xxd
      unzip
      usbutils
      wget

      comma
    ];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
        LANGUAGE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
    };
  };

  networking = {
    nameservers = [ "127.0.0.1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";

    firewall = {
      # Allow PMTU / DHCP
      allowPing = true;

      # Keep dmesg/journalctl -k output readable by NOT logging
      # each refused connection on the open internet.
      logRefusedConnections = false;
    };

    # useNetworkd = true;
  };

  nix = {
    channel.enable = false;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      connect-timeout = 5;
      log-lines = 25;
      max-free = (3000 * 1024 * 1024);
      min-free = (512 * 1024 * 1024);
      builders-use-substitutes = true;
    };

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
  };

  programs = {
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 14d";
      };
      flake = "/home/alex/nixos-config";
    };

    ssh.knownHosts = {
      "github.com".hostNames = [ "github.com" ];
      "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

      "u278697.your-storagebox.de".hostNames = [ "u278697.your-storagebox.de" ];
      "u278697.your-storagebox.de".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";

      # [u278697.your-storagebox.de]:23 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs
      # [u278697.your-storagebox.de]:23 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==
      # [u278697.your-storagebox.de]:23 ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==
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
        X11Forwarding = false;
        KbdInteractiveAuthentication = false;
        UseDns = false;
        # unbind gnupg sockets if they exists
        StreamLocalBindUnlink = true;

        # Use key exchange algorithms recommended by `nixpkgs#ssh-audit`
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
      };
      openFirewall = true;
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

  # The notion of "online" is a broken concept
  # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
  systemd = {
    services.NetworkManager-wait-online.enable = false;
    network.wait-online.enable = false;

    # FIXME: Maybe upstream?
    # Do not take down the network for too long when upgrading,
    # This also prevents failures of services that are restarted instead of stopped.
    # It will use `systemctl restart` rather than stopping it with `systemctl stop`
    # followed by a delayed `systemctl start`.
    services.systemd-networkd.stopIfChanged = false;
    # Services that are only restarted might be not able to resolve when resolved is stopped before
    # services.systemd-resolved.stopIfChanged = false;

    services.nix-gc.serviceConfig = {
      CPUSchedulingPolicy = "batch";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };

    services.nix-daemon.serviceConfig.OOMScoreAdjust = 250;

    # default is something like vt220... however we want to get alt least some colors...
    # services."serial-getty@".environment.TERM = "xterm-256color";
  };

  system.activationScripts.update-diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        echo "--- diff to current-system"
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
        echo "---"
      fi
    '';
  };
}
