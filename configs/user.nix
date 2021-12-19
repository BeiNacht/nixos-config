{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" "kvm" "lp" "scanner" "adbusers" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPSzeNjfkz7/B/18TcJxxmNFUhvTKoieBcexdzebWH7oncvyBXNRJp8vAqSIVFLzz5UUFQNFuilggs8/N48U84acmFOxlbUmxlkf8KZgeB/G6uQ8ncQh6M1HNNPH+9apTURgfctr7eEZe9seLIEBISQLXB2Sf3F1ogfDj25S8kH9RM4wM1/jDFK5IecWHScKxwQPmCoXeGE1LEJq6nkQLXMDsWhSihtWouaTxSR0p7/wp/Rqt/hzLEWj8e3+qLMc5JrrdaWksupUCysme7CnSfGSzNUv9RKiRCTFofYPT9tbRn5JzdpQ55v22S6OvmmXUHjST1MOzI8MpVPZCCqd/ZQ1E+gErFiMwjG4sn/xxdPK9/jbQaXMjLklbKtR+C5090Ew2u2kj78jqGk/8COhF1MXh/9qjcG+C51uD1AS9d410kfjPwkaUt4U2KktDMQ942nWywrvIWM0Gt2kgDLYotsy/70q/aTJ8bvaCoWoDOGmpWcyNNBalz4OYYGI2Z0WHrVTs0FpzSk/XeQz0OLkmueoh5GDGd8zrfO6Nf5LWI17aWGRePTpQP5mJIg6jC3j8/QVrthEP6QyIIkZsnfsmvSiMWVfXqEy1BxVlu3T6aLffaj679KCsxY+mx5mTH2hwd4ZdbSI4F0GCIt+WGaFhHs2V3ZQitoEZuraRPEc4HGw== alexander@szczepan.ski"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIsOYaj6+akcgTQPvm0/htYgO5z+PR1TJRxCnbRNI/ucqvcC6/eTzPU7tKG+UJtkfy30NSnwu/k9aENyb5zYLVoDHngOzH8DLl93B2nHgwUiLpv7kFXOhvD1jsA5RsryeumaL7YbtlePrso+FEJkUez8mncAjG4t9U/MifkTbujjS5AP35NONH01fQWKvivnqw4T0dq36e0J0YF/zcb1mQovt3dw7+NE0A6OwNGAElRNwVh619jL9g0TJBi3Ge8LASsHBildzTlNVHzIwdDzRdAvsoAXjYF42fjHSQXZJv5P5eJcT7JEt7x+yVWzTnk/K6/dtKi6kewbp/srUGSsVLP6x+o6QTQ5rYKoBRsM/3bfqG0PwijfDXEdn7bQn6+7PcnMhVi5wJppUeEOt0SbRBDSa3ewzTWjjESPW03b/oIlNrnDhk5UJmF5jlfxz9HHP73lqEpcNhEAiZMLbfvnwtufS/wYnZXz44i8rVEiNMfIOS2VIM74aNloPTvkq0Ek0GzTT6H4wQy7VbRgSOaW+XN5TSOEqtfZ0TpmYNrpskVx5yDrbOOArmULICGLlexed8fsFZX8P1ouTg96pM5Kr47HZsdEZzS8DKuDx8EP50ORYKbN6Kyb+f0FcMEfD1RQV+IECKnnFUyoozFjE0aV+ROjAKoDmyWdU2lpOPA8kRBw== alex@desktop"
      ];
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      packages = with unstable.pkgs; [
        exa
        broot
        ffmpeg
        tealdeer
        atop
        bpytop
        dfc
        git-secret
        glances
        htop
        kubectl
        ncdu
        neofetch
        pstree
        ranger
        sshfs
        unrar
        youtube-dl
      ];
      sessionPath = [
        "$HOME/.npm-packages"
        "$HOME/.bin"
      ];
      file = {
        ".npmrc" = {
          source = ../home/npmrc;
        };
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

        matchBlocks."old-vps" = {
          hostname = "2.56.97.114";
          localForwards = [{
            bind.address = "127.0.0.1";
            bind.port = 8386;
            host.address = "127.0.0.1";
            host.port = 8384;
          }
            {
              bind.address = "127.0.0.1";
              bind.port = 9092;
              host.address = "127.0.0.1";
              host.port = 9091;
            }];
        };

        matchBlocks."szczepan.ski" = {
          hostname = "207.180.220.97";
          localForwards = [
            {
              bind.address = "127.0.0.1";
              bind.port = 8387;
              host.address = "127.0.0.1";
              host.port = 8384;
            }
            {
              bind.address = "127.0.0.1";
              bind.port = 9092;
              host.address = "127.0.0.1";
              host.port = 9091;
            }
          ];
        };

        matchBlocks."nixos-vm" = {
          hostname = "192.168.122.222";
          remoteForwards = [{
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent";
          }];
        };

        matchBlocks."mini" = {
          hostname = "192.168.0.101";
        };

        matchBlocks."pi" = {
          hostname = "192.168.1.143";
        };

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
        enableSyntaxHighlighting = true;
        oh-my-zsh = {
          enable = true;
          plugins = [
            "cp"
            "common-aliases"
            "docker"
            "systemd"
            "wd"
            "kubectl"
            "git"
          ];
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
          active-services = "systemctl --no-page --no-legend --plain -t service --state=running";
          autofanspeed = "echo level auto | sudo tee /proc/acpi/ibm/fan";
          maxfanspeed = "echo level full-speed | sudo tee /proc/acpi/ibm/fan";
          db = "sudo updatedb";
          "-g C" = "| wc -l";
          "-g G" = "| grep --ignore-case";
          bat = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
          brightness-max = "echo 4794 | sudo tee /sys/class/backlight/intel_backlight/brightness";
          brightness-power-save = "echo 2300 | sudo tee /sys/class/backlight/intel_backlight/brightness";
          ff = "find . -type f -iname";
          l = "exa --group-directories-first -l -g";
          ll = "exa --group-directories-first -l -g";
          la = "exa --group-directories-first -l -g -a";
        };
      };

      tmux = {
        enable = true;
      };

      # exa = {
      #   enable = true;
      #   enableAliases = true;
      # };
    };

    # manuals not needed
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = false;
  };
}
