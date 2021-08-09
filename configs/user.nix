{ config, pkgs, lib, ... }:
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" "lp" "scanner" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPSzeNjfkz7/B/18TcJxxmNFUhvTKoieBcexdzebWH7oncvyBXNRJp8vAqSIVFLzz5UUFQNFuilggs8/N48U84acmFOxlbUmxlkf8KZgeB/G6uQ8ncQh6M1HNNPH+9apTURgfctr7eEZe9seLIEBISQLXB2Sf3F1ogfDj25S8kH9RM4wM1/jDFK5IecWHScKxwQPmCoXeGE1LEJq6nkQLXMDsWhSihtWouaTxSR0p7/wp/Rqt/hzLEWj8e3+qLMc5JrrdaWksupUCysme7CnSfGSzNUv9RKiRCTFofYPT9tbRn5JzdpQ55v22S6OvmmXUHjST1MOzI8MpVPZCCqd/ZQ1E+gErFiMwjG4sn/xxdPK9/jbQaXMjLklbKtR+C5090Ew2u2kj78jqGk/8COhF1MXh/9qjcG+C51uD1AS9d410kfjPwkaUt4U2KktDMQ942nWywrvIWM0Gt2kgDLYotsy/70q/aTJ8bvaCoWoDOGmpWcyNNBalz4OYYGI2Z0WHrVTs0FpzSk/XeQz0OLkmueoh5GDGd8zrfO6Nf5LWI17aWGRePTpQP5mJIg6jC3j8/QVrthEP6QyIIkZsnfsmvSiMWVfXqEy1BxVlu3T6aLffaj679KCsxY+mx5mTH2hwd4ZdbSI4F0GCIt+WGaFhHs2V3ZQitoEZuraRPEc4HGw== alexander@szczepan.ski"
      ];
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.alex = { pkgs, ... }: {
    home.enableNixpkgsReleaseCheck = false;
    # home.packages =  with pkgs; [
    # ];

    programs = {
      ssh = {
        enable = true;
        compression = true;
        serverAliveInterval = 60;
        forwardAgent = true;

        matchBlocks."szczepan.ski" = {
          hostname = "szczepan.ski";
        };

        matchBlocks."nixos-vm" = {
          hostname = "192.168.122.33";
        };

        matchBlocks."mini" = {
          hostname = "192.168.0.87";
        };

        matchBlocks."router" = {
          hostname = "192.168.1.1";
          user = "root";
          localForwards = [ {
            bind.address = "127.0.0.1";
            bind.port = 1337;
            host.address = "127.0.0.1";
            host.port = 80;
          } ];
        };

        matchBlocks."homeserver" = {
          hostname = "192.168.1.100";
        };
      };

      git = {
        enable = true;
        userName  = "Alexander Szczepanski";
        userEmail = "alexander@szczepan.ski";
        extraConfig = {
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
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "powerlevel10k-config";
            src = lib.cleanSource ./p10k-config;
            file = "p10k.zsh";
          }
        ];
        localVariables = {
          SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
        };
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
