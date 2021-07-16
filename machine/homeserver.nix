{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../configs/common.nix
      ../configs/virtualisation.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homeserver"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "render" ]; # Enable ‘sudo’ for the user.
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    snapraid
    mergerfs
    samba
    openssl
    hdparm
    smartmontools
    docker-compose
  ];

  systemd.mounts = [
    {
      requires = [
        "mnt-disk1.mount"
        "mnt-disk2.mount"
        "mnt-disk3.mount"
      ];
      after = [
        "mnt-disk1.mount"
        "mnt-disk2.mount"
        "mnt-disk3.mount"
      ];
      what = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
      where = "/mnt/storage";
      type = "fuse.mergerfs";
      options = "defaults,allow_other,use_ino,fsname=mergerfs,minfreespace=50G,func.getattr=newest,noforget";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/3e1731d7-f17e-4f6d-9197-84e0492bf4ee
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa
    ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d
    ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b
    ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/3e1731d7-f17e-4f6d-9197-84e0492bf4ee
    ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa
  '';

  systemd.services.snapraid-sync = {
    #enable = true;
    description = "Snapraid Sync and Diff";
    serviceConfig = {
      Type = "oneshot";
      User = "alex";
      # ExecStart="/home/alex/snapraid-sync";
    };
    path = [pkgs.bash pkgs.snapraid pkgs.curl pkgs.smartmontools pkgs.hdparm];

    script = ''
      /home/alex/snapraid-sync
    '';
  };

  systemd.timers.snapraid-sync = {
    #enable = true;
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Mon-Sun, 23:00";
      # Unit = "snapraid-sync.service";
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      #intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  services.netdata.enable = true;

  services.jellyfin = {
    enable = true;
    user = "alex";
    group = "users";
  };

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = server
      netbios name = server
      security = user
      guest account = nobody
      map to guest = bad user
      logging = systemd
      max log size = 50
    '';
    shares = {
      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      ssdstorage = {
        path = "/mnt/ssdstorage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  security.sudo.extraRules = [ {
    users = [ "alex" ];
    commands = [ {
      command = "${pkgs.hdparm}/bin/hdparm";
      options = [ "SETENV" "NOPASSWD" ];
    } ];
  } {
    users = [ "alex" ];
    commands = [ {
      command = "${pkgs.snapraid}/bin/snapraid";
      options = [ "SETENV" "NOPASSWD" ];
    } ];
  }];

  # Open ports in the firewall.
  # networking.firewall.enable = true;
  # networking.firewall.allowPing = true;
  # networking.firewall.allowedTCPPorts = [ 445 139 19999 ];
  # networking.firewall.allowedUDPPorts = [ 137 138 19999 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
