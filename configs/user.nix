{ config, pkgs, lib, ... }:
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" "lp" "scanner" ];
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.alex = { pkgs, ... }: {
    home.packages = [
      pkgs.cryfs
    ];

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
          # remoteForwards = [ {
          #   bind.address = "127.0.0.1";
          #   bind.port = 52698;
          #   host.address = "127.0.0.1";
          #   host.port = 52698;
          # } ];
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
        oh-my-zsh = {
          enable = true;
          plugins = [
            "cp"
            "common-aliases"
            "docker "
            "systemd"
            "wd"
            "kubectl"
            "git"
          ];
          theme = "agnoster";
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
          EDITOR = "vim";
        };
        shellAliases = {
          lw = "lorri watch --once";
          mff = "git merge --ff-only";
          vi = "vim";
        };
        initExtra = ''
          unset LESS
        '';
      };
    };

    # manuals not needed
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = false;
  };
}
