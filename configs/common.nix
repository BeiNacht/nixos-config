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

  environment = {
    systemPackages = with pkgs; [
      borgbackup
      # btrfs-progs # utils for btrfs
      doggo # DNS Resolver
      dust
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
      # glances # baut aktuell nicht
      nmap
      bandwhich
      lsof

      gping

      gnupg
      # hdparm
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
      # usbutils
      wget

      broot
      git-secret
      # neofetch
      ranger # terminal filemanager
      superfile # terminal filemanager

      unrar
      unzip

      ffmpeg
      yt-dlp # to download youtube stuff
      gocryptfs # file encryption
      sshfs
      tealdeer # shorter man pages
      man-pages
      man-pages-posix

      stow
      jq
      # mas
    ];
  };

  programs = {
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

      "homeserver" = {
        hostNames = ["homeserver.meteor-altered.ts.net"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINM6ZhCW90TYDwvbObs3DUF0k0Xb3z60WOOKNi0FaDEP";
      };
    };
  };
}
