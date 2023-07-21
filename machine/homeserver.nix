{ config, pkgs, ... }:

let secrets = import ../configs/secrets.nix;
in {
  imports = [
    <nixos-hardware/common/cpu/intel>
    /etc/nixos/hardware-configuration.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/libvirt.nix
    ../configs/user.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "homeserver"; # Define your hostname.
    useDHCP = false;
    firewall.enable = false;
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp3s0";
    };

    wireless = {
      enable = true;
      networks.Skynet_5G.psk = secrets.wifipassword;
      interfaces = [ "wlp1s0" ];
    };

    # libvirt uses 192.168.122.0
    bridges.br0.interfaces = [ ];
    interfaces.br0 = {
      ipv4.addresses = [{
        address = "192.168.122.1";
        prefixLength = 24;
      }];
    };

    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp1s0.useDHCP = true;
  };

  environment.systemPackages = with pkgs; [
    snapraid
    mergerfs
    samba
    openssl
    smartmontools
  ];

  systemd = {
    mounts = [{
      requires = [ "mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount" ];
      after = [ "mnt-disk1.mount" "mnt-disk2.mount" "mnt-disk3.mount" ];
      what = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
      where = "/mnt/storage";
      type = "fuse.mergerfs";
      options =
        "defaults,allow_other,use_ino,fsname=mergerfs,minfreespace=50G,func.getattr=newest,noforget";
      wantedBy = [ "multi-user.target" ];
    }];

    services.snapraid-sync = {
      description = "Snapraid Sync and Diff";
      serviceConfig = {
        Type = "oneshot";
        User = "alex";
      };
      path = [
        pkgs.bash
        pkgs.snapraid
        pkgs.curl
        pkgs.smartmontools
        pkgs.hdparm
        pkgs.exfatprogs
        pkgs.exfat
      ];

      script = ''
        /home/alex/snapraid-sync
      '';
    };

    timers.snapraid-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnCalendar = "Mon-Sun, 23:00"; };
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "powersave";

    powerUpCommands = ''
      ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d
      ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b
      ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/3e1731d7-f17e-4f6d-9197-84e0492bf4ee
      ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa
      ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/0301db98-264f-4b18-9423-15691063f73d
      ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/3c4b5d00-43c0-48be-81b8-c2b3977e015b
      ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/3e1731d7-f17e-4f6d-9197-84e0492bf4ee
      ${pkgs.hdparm}/sbin/hdparm -y /dev/disk/by-uuid/6cce037c-d2d4-4940-bb69-6d2b84fd41aa
    '';
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      #intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services = {
    netdata.enable = false;

    jellyfin = {
      enable = true;
      user = "alex";
      group = "users";
    };

    samba = {
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
      };
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "alex" ];
      commands = [{
        command = "${pkgs.hdparm}/bin/hdparm";
        options = [ "SETENV" "NOPASSWD" ];
      }];
    }
    {
      users = [ "alex" ];
      commands = [{
        command = "${pkgs.snapraid}/bin/snapraid";
        options = [ "SETENV" "NOPASSWD" ];
      }];
    }
  ];

  system.stateVersion = "23.05";
}
