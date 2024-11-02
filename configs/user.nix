{ config, pkgs, lib, inputs, ... }:
let
  serviceConfig = {
    MountAPIVFS = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProtectKernelModules = true;
    PrivateDevices = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectSystem = "full";
    RestrictSUIDSGID = true;
  };
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    users.alex = {
      isNormalUser = true;
      uid = 1000;
      hashedPasswordFile = config.sops.secrets.hashedPassword.path;
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
        "lp"
        "nginx"
        "scanner"
        "adbusers"
        "locatedb"
        "davfs2"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
      ];
    };
  };

  systemd.services = {
    alex.serviceConfig = serviceConfig;
    root.serviceConfig = serviceConfig;
  };

  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
  };

  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      stateVersion = "24.11";
      packages = with pkgs; [
        broot
        ffmpeg
        git-secret
        kubectl
        neofetch
        nixfmt-classic
        pstree
        qrencode
        ranger
        sshfs
        tealdeer
        unrar
        yt-dlp

        nix-output-monitor
      ];

      sessionPath = [ "$HOME/.npm-packages" "$HOME/.bin" ];
      file = {
        ".npmrc" = { source = ../home/npmrc; };
        ".bin/git-redate" = {
          executable = true;
          source = ../home/bin/git-redate;
        };
        ".bin/backup-to-stick" = {
          executable = true;
          source = ../home/bin/backup-to-stick;
        };
      };
    };

    programs = {
      ssh = {
        enable = true;
        compression = true;
        serverAliveInterval = 60;
        forwardAgent = true;

        matchBlocks."szczepan.ski" = { hostname = "szczepan.ski"; };
        matchBlocks."mini" = { hostname = "mini"; };
        matchBlocks."nixos-vm" = {
          hostname = "127.0.0.1";
          port = 1337;
        };

        matchBlocks."thinkpad" = { hostname = "thinkpad"; };
      };

      git = {
        enable = true;
        userName = "Alexander Szczepanski";
        userEmail = "alexander@szczepan.ski";
        extraConfig = {
          core = { autocrlf = false; };
          color = { ui = "auto"; };
          push = { default = "current"; };
          pull = { rebase = true; };
        };
      };

      zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        oh-my-zsh = {
          enable = true;
          plugins =
            [ "cp" "common-aliases" "docker" "systemd" "wd" "kubectl" "git" ];
        };
        plugins = [
          {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "powerlevel10k-config";
            src = lib.cleanSource ./p10k-config;
            file = "p10k.zsh";
          }
        ];
        shellAliases = {
          active-services =
            "systemctl --no-page --no-legend --plain -t service --state=running";
          db = "sudo updatedb";
          "-g C" = "| wc -l";
          "-g G" = "| grep --ignore-case";
          ff = "find . -type f -iname";
          l = "lsd -lh --group-directories-first";
          ll = "lsd -lh --group-directories-first";
          la = "lsd -lah --group-directories-first";

          # bat = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
          # autofanspeed = "echo level auto | sudo tee /proc/acpi/ibm/fan";
          # maxfanspeed = "echo level full-speed | sudo tee /proc/acpi/ibm/fan";
        };
      };

      tmux = { enable = true; };
    };
  };
}
