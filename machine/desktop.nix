{ config, pkgs, inputs, outputs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  wireguard = import ../configs/wireguard.nix;
in
{
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./desktop-hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../configs/browser.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/games.nix
    ../configs/libvirt.nix
    ../configs/plasma.nix
    ../configs/user-gui.nix
    ../configs/user.nix
  ];

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-znver2" ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = { canTouchEfiVariables = true; };
    };

    extraModulePackages = with pkgs.linuxPackages; [ it87 ];
    kernelModules = [ "it87" ];
    # kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  };

  systemd.services = {
    monitor = {
      description = "AMDGPU Control Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = { ExecStart = "${pkgs.unstable.lact}/bin/lact daemon"; };
    };
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
    # wireguard.interfaces = {
    #   wg0 = {
    #     ips = [ "10.100.0.2/24" ];
    #     privateKey = secrets.wireguard-desktop-private;
    #     peers = [{
    #       publicKey = wireguard.wireguard-vps-public;
    #       presharedKey = secrets.wireguard-preshared;
    #       allowedIPs = [ "10.100.0.0/24" ];
    #       endpoint = "old.szczepan.ski:51820";
    #       persistentKeepalive = 25;
    #     }];
    #   };
    # };
  };

  time.timeZone = "Europe/Berlin";

  console = {
    font = "latarcyrheb-sun32";
    keyMap = "us";
  };

  environment.systemPackages = with pkgs.unstable; [
    lact
    amdgpu_top

    python3
    python311Packages.tkinter

    snapraid
    mergerfs
  ];

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    xone.enable = true;

    bluetooth.enable = true;
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      # extraPackages = with pkgs; [
      #   rocm-opencl-icd
      #   rocm-opencl-runtime
      #   amdvlk
      # ];
      # extraPackages32 = with pkgs; [
      #   driversi686Linux.amdvlk
      # ];
    };

    fancontrol = {
      enable = true;
      config = ''
        INTERVAL=10
        DEVPATH=hwmon3=devices/platform/it87.656
        DEVNAME=hwmon3=it8665
        FCTEMPS=hwmon3/pwm3=hwmon2/temp1_input hwmon3/pwm2=hwmon2/temp1_input hwmon3/pwm1=hwmon2/temp1_input
        FCFANS=hwmon3/pwm3=hwmon3/fan3_input hwmon3/pwm2=hwmon3/fan2_input hwmon3/pwm1=hwmon3/fan1_input
        MINTEMP=hwmon3/pwm3=60 hwmon3/pwm2=60 hwmon3/pwm1=60
        MAXTEMP=hwmon3/pwm3=80 hwmon3/pwm2=80 hwmon3/pwm1=80
        MINSTART=hwmon3/pwm3=51 hwmon3/pwm2=51 hwmon3/pwm1=51
        MINSTOP=hwmon3/pwm3=51 hwmon3/pwm2=51 hwmon3/pwm1=51
        MINPWM=hwmon3/pwm1=51 hwmon3/pwm2=51 hwmon3/pwm3=51
        MAXPWM=hwmon3/pwm3=127 hwmon3/pwm2=153 hwmon3/pwm1=153
      '';
    };

    pulseaudio.enable = false;
  };

  sound.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    netdata.enable = true;
    printing.enable = true;
    fwupd.enable = true;

    displayManager.autoLogin = {
      enable = true;
      user = "alex";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
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
          path = "/home/alex/shared/storage";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    tailscale.enable = true;

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs = "--checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i ~/.ssh/id_borg_ed25519";
      paths = "/home/alex";
      repo = secrets.borg-repo;
      startAt = "daily";
      user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  system.stateVersion = "24.05";
}
