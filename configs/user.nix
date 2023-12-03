{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  secrets = import ./secrets.nix;
in
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    users.alex = {
      isNormalUser = true;
      hashedPassword = secrets.hashedPassword;
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
        "libvirtd"
        "kvm"
        "lp"
        "nginx"
        "scanner"
        "adbusers"
        "locatedb"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPSzeNjfkz7/B/18TcJxxmNFUhvTKoieBcexdzebWH7oncvyBXNRJp8vAqSIVFLzz5UUFQNFuilggs8/N48U84acmFOxlbUmxlkf8KZgeB/G6uQ8ncQh6M1HNNPH+9apTURgfctr7eEZe9seLIEBISQLXB2Sf3F1ogfDj25S8kH9RM4wM1/jDFK5IecWHScKxwQPmCoXeGE1LEJq6nkQLXMDsWhSihtWouaTxSR0p7/wp/Rqt/hzLEWj8e3+qLMc5JrrdaWksupUCysme7CnSfGSzNUv9RKiRCTFofYPT9tbRn5JzdpQ55v22S6OvmmXUHjST1MOzI8MpVPZCCqd/ZQ1E+gErFiMwjG4sn/xxdPK9/jbQaXMjLklbKtR+C5090Ew2u2kj78jqGk/8COhF1MXh/9qjcG+C51uD1AS9d410kfjPwkaUt4U2KktDMQ942nWywrvIWM0Gt2kgDLYotsy/70q/aTJ8bvaCoWoDOGmpWcyNNBalz4OYYGI2Z0WHrVTs0FpzSk/XeQz0OLkmueoh5GDGd8zrfO6Nf5LWI17aWGRePTpQP5mJIg6jC3j8/QVrthEP6QyIIkZsnfsmvSiMWVfXqEy1BxVlu3T6aLffaj679KCsxY+mx5mTH2hwd4ZdbSI4F0GCIt+WGaFhHs2V3ZQitoEZuraRPEc4HGw== alexander@szczepan.ski"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
      ];
    };
  };

  programs.zsh.enable = true;

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.alex = { pkgs, ... }: {
#    imports = [
#      "${
#        fetchTarball
#        "https://github.com/msteen/nixos-vscode-server/tarball/master"
#      }/modules/vscode-server/home.nix"
#    ];

    home = {
      stateVersion = "23.05";
      packages = with unstable.pkgs; [
        atop
        btop
        broot
        dfc
        eza
        ffmpeg
        git-secret
        glances
        htop
        kubectl
        ncdu
        neofetch
        nixfmt
        pstree
        qrencode
        ranger
        sshfs
        tealdeer
        unrar
        yt-dlp
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

        matchBlocks."szczepan.ski" = { hostname = "207.180.220.97"; };
        matchBlocks."mini" = { hostname = "10.100.0.3"; };
        matchBlocks."thinkpad" = { hostname = "10.100.0.8"; };
        matchBlocks."pi" = { hostname = "10.100.0.6"; };
        matchBlocks."vps2" = { hostname = "10.100.0.50"; };
        matchBlocks."vps3" = { hostname = "10.100.0.100"; };
        matchBlocks."router" = {
          hostname = "192.168.1.1";
          user = "root";
          localForwards = [{
            bind.address = "127.0.0.1";
            bind.port = 1337;
            host.address = "127.0.0.1";
            host.port = 80;
          }];
        };

        matchBlocks."homeserver" = {
          hostname = "192.168.0.100";
          localForwards = [{
            bind.address = "127.0.0.1";
            bind.port = 8385;
            host.address = "127.0.0.1";
            host.port = 8384;
          }];
        };
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
        enableAutosuggestions = true;
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
            src = unstable.pkgs.zsh-powerlevel10k;
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
          brightness-max =
            "echo 4794 | sudo tee /sys/class/backlight/intel_backlight/brightness";
          brightness-power-save =
            "echo 2300 | sudo tee /sys/class/backlight/intel_backlight/brightness";
          ff = "find . -type f -iname";
          l = "eza --group-directories-first -l -g";
          ll = "eza --group-directories-first -l -g";
          la = "eza --group-directories-first -l -g -a";
        };
      };

      tmux = { enable = true; };
    };

#    services.vscode-server.enable = true;
  };
}
