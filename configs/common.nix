{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 5;
        enableCryptodisk = true;
        useOSProber = true;
      };
    };

    tmp = {
      useTmpfs = lib.mkDefault true;
      cleanOnBoot = true;
    };
    consoleLogLevel = 0;
    kernel.sysctl = {"vm.max_map_count" = 262144;};
    supportedFilesystems = ["ntfs" "btrfs"];

    initrd = {
      postDeviceCommands = pkgs.lib.mkBefore ''
        mkdir -p /mnt

        # We first mount the btrfs root to /mnt
        # so we can manipulate btrfs subvolumes.
        mount -o subvol=/ /dev/mapper/lvm-root /mnt

        # While we're tempted to just delete /root and create
        # a new snapshot from /root-blank, /root is already
        # populated at this point with a number of subvolumes,
        # which makes `btrfs subvolume delete` fail.
        # So, we remove them first.
        #
        # /root contains subvolumes:
        # - /root/var/lib/portables
        # - /root/var/lib/machines
        #
        # I suspect these are related to systemd-nspawn, but
        # since I don't use it I'm not 100% sure.
        # Anyhow, deleting these subvolumes hasn't resulted
        # in any issues so far, except for fairly
        # benign-looking errors from systemd-tmpfiles.
        btrfs subvolume list -o /mnt/root |
        cut -f9 -d' ' |
        while read subvolume; do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "/mnt/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete /mnt/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /mnt/root-blank /mnt/root

        # Once we're done rolling back to a blank snapshot,
        # we can unmount /mnt and continue on the boot process.
        umount /mnt
      '';
    };
  };

  # Work around for https://github.com/NixOS/nixpkgs/issues/124215
  documentation.info.enable = false;

  environment = {
    # Don't install the /lib/ld-linux.so.2 stub. This saves one instance of nixpkgs.
    ldso32 = null;

    shells = with pkgs; [bashInteractive zsh];

    systemPackages = with pkgs; [
      borgbackup
      btrfs-progs # utils for btrfs
      doggo # DNS Resolver
      du-dust
      ncdu
      duf # dfc alternative
      lsd # eza alternative
      bat # cat alternative
      pstree

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
      lsof
      lm_sensors

      gnupg
      hdparm
      inxi # hardware list
      kitty.terminfo

      tre-command

      # nix
      nil # nix language server
      nix-tree # like ncdu for nix store
      nixd # nix diff
      alejandra # nix formating

      parallel
      pciutils
      progress
      unixtools.xxd
      usbutils
      wget

      broot
      git-secret
      neofetch
      ranger # terminal filemanager

      unrar
      unzip

      ffmpeg
      yt-dlp # to download youtube stuff
      gocryptfs # file encryption
      sshfs
      tealdeer # shorter man pages
      man-pages
      man-pages-posix
    ];

    persistence."/persist" = {
      directories = [
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/tuptime"
        "/var/lib/vnstat"
      ];
      files = [
        "/etc/machine-id"
        "/etc/NIXOS"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LANGUAGE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
      "de_DE/ISO-8859-1"
    ];
  };

  networking = {
    nameservers = ["127.0.0.1"];
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
    nixPath = ["nixpkgs=${inputs.nixpkgs-unstable}"];
    channel.enable = false;
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      connect-timeout = 5;
      log-lines = 25;
      max-free = 3000 * 1024 * 1024;
      min-free = 512 * 1024 * 1024;
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
      "github.com" = {
        hostNames = ["github.com"];
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
      };

      "github.com-2" = {
        hostNames = ["github.com"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };

      "github.com-3" = {
        hostNames = ["github.com"];
        publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
      };

      "u278697.your-storagebox.de" = {
        hostNames = ["[u278697.your-storagebox.de]:23"];
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
      };

      "u278697.your-storagebox.de-2" = {
        hostNames = ["[u278697.your-storagebox.de]:23"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      };

      "u278697.your-storagebox.de-3" = {
        hostNames = ["[u278697.your-storagebox.de]:23"];
        publicKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };
    };
  };

  services = {
    vnstat.enable = true;
    tuptime.enable = true;
    locate.enable = true;
    tailscale.enable = true;

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

    journald = {extraConfig = "SystemMaxUse=500M";};
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

  # Turn off sudo lecture
  security = {
    sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';
  };
}
