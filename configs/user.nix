{ config, pkgs, lib, inputs, ... }:
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
      # hashedPassword = secrets.hashedPassword;
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

  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
  };

  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      stateVersion = "24.05";
      packages = with pkgs.unstable; [
        # atop
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
        matchBlocks."thinkpad" = { hostname = "thinkpad"; };
        # matchBlocks."pi" = { hostname = "10.100.0.6"; };
        # matchBlocks."vps2" = { hostname = "10.100.0.50"; };
        # matchBlocks."vps3" = { hostname = "10.100.0.100"; };
        # matchBlocks."router" = {
        #   hostname = "192.168.1.1";
        #   user = "root";
        #   localForwards = [{
        #     bind.address = "127.0.0.1";
        #     bind.port = 1337;
        #     host.address = "127.0.0.1";
        #     host.port = 80;
        #   }];
        # };

        # matchBlocks."homeserver" = {
        #   hostname = "192.168.0.100";
        #   localForwards = [{
        #     bind.address = "127.0.0.1";
        #     bind.port = 8385;
        #     host.address = "127.0.0.1";
        #     host.port = 8384;
        #   }];
        # };
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
            src = pkgs.unstable.zsh-powerlevel10k;
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
          autofanspeed = "echo level auto | sudo tee /proc/acpi/ibm/fan";
          maxfanspeed = "echo level full-speed | sudo tee /proc/acpi/ibm/fan";
          db = "sudo updatedb";
          "-g C" = "| wc -l";
          "-g G" = "| grep --ignore-case";
          bat = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
          ff = "find . -type f -iname";
          l = "eza --group-directories-first -l -g";
          ll = "eza --group-directories-first -l -g";
          la = "eza --group-directories-first -l -g -a";
        };
      };

      tmux = { enable = true; };
    };
  };
}
