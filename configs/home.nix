{
  pkgs,
  inputs,
  lib,
  ...
}: {
  home = {
    stateVersion = "24.11";

    sessionPath = ["$HOME/.npm-packages" "$HOME/.bin"];
    file = {
      ".npmrc" = {source = ../home/npmrc;};
      ".bin/git-redate" = {
        executable = true;
        source = ../home/bin/git-redate;
      };
      ".bin/backup-to-stick" = {
        executable = true;
        source = ../home/bin/backup-to-stick;
      };

      # ".cache/nix-index/files".source =
      #   inputs.nix-index-database.legacyPackages.${pkgs.system}.database;
    };

    packages = with pkgs; [ueberzugpp];
  };

  programs = {
    bat = {
      enable = true;
      config = {
        italic-text = "always";
        # theme = "catppuccin";
      };
    };

    ssh = {
      enable = true;

      matchBlocks = {
        "*" = {
          compression = true;
          serverAliveInterval = 60;
          forwardAgent = true;
          addKeysToAgent = "yes";
        };
        "szczepan.ski" = {hostname = "szczepan.ski";};
        "mini" = {hostname = "mini";};
        "homeserver" = {hostname = "homeserver";};
        "desktop" = {hostname = "desktop";};
        "framework" = {hostname = "framework";};
        "thinkpad" = {hostname = "thinkpad";};
        "nixos-vm" = {
          hostname = "127.0.0.1";
          port = 1337;
        };
      };
    };

    git = {
      enable = true;
      userName = "Alexander Szczepanski";
      userEmail = "alexander@szczepan.ski";
      settings = {
        user = {
          name = "Alexander Szczepanski";
          email = "alexander@szczepan.ski";
        };
        core = {autocrlf = false;};
        color = {ui = "auto";};
        push = {default = "current";};
        pull = {rebase = true;};
      };
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = ["cp" "common-aliases" "docker" "systemd" "wd" "kubectl" "git"];
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
        active-services = "systemctl --no-page --no-legend --plain -t service --state=running";
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

    tmux = {
      enable = true;
      historyLimit = 100000;
      mouse = true;
      keyMode = "vi";
      escapeTime = 5;
      baseIndex = 1;
      shortcut = "a";
      terminal = "xterm-256color";
      plugins = with pkgs.tmuxPlugins; [
        # {
        #   # https://github.com/catppuccin/tmux
        #   # Soothing pastel theme for Tmux!
        #   plugin = catppuccin;
        #   extraConfig = ''
        #     set -g @catppuccin_window_left_separator ""
        #     set -g @catppuccin_window_right_separator " "
        #     set -g @catppuccin_window_middle_separator " █"
        #     set -g @catppuccin_window_number_position "right"

        #     set -g @catppuccin_window_default_fill "number"
        #     set -g @catppuccin_window_default_text "#W"

        #     set -g @catppuccin_window_current_fill "number"
        #     set -g @catppuccin_window_current_text "#W"

        #     set -g @catppuccin_status_modules "directory"
        #     set -g @catppuccin_status_left_separator  " "
        #     set -g @catppuccin_status_right_separator ""
        #     set -g @catppuccin_status_right_separator_inverse "no"

        #     set -g @catppuccin_status_fill "icon"
        #     set -g @catppuccin_window_status_icon_enable "yes"
        #     set -g @catppuccin_status_connect_separator "no"

        #     set -g @catppuccin_date_time_text "%Y-%m-%d %H:%M:%S"
        #     set -g @catppuccin_directory_text "#{pane_current_path}"
        #   '';
        # }
        {
          # https://github.com/tmux-plugins/tmux-yank
          # Tmux plugin for copying to system clipboard.
          plugin = yank;
        }
        {
          # https://github.com/tmux-plugins/tmux-resurrect
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-processes ':all:'
          '';
        }
        {
          # https://github.com/tmux-plugins/tmux-continuum
          # Continuous saving of tmux environment.
          # Automatic restore when tmux is started.
          # Automatic tmux start when computer is turned on.
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-save-interval '120'
            set -g @continuum-restore 'on'
          '';
        }
        {
          # https://github.com/tmux-plugins/tmux-pain-control
          # standard pane key-bindings for tmux
          plugin = pain-control;
          extraConfig = ''
            # Focus events enabled for terminals that support them
            set -g focus-events on

            # Super useful when using "grouped sessions" and multi-monitor setup
            setw -g aggressive-resize on

            # Give back my C-a C-a (helix)
            unbind C-a
            bind-key C-a send-prefix
          '';
        }
      ];
      extraConfig = ''
        # Enables italics in tmux
        set -ga terminal-overrides ",xterm-256color*:Tc"

        # Enable yazi image preview
        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
      '';
    };
  };
}
