{ config, pkgs, lib, outputs, inputs, ... }:
let
  be = import ../configs/borg-exclude.nix;
  secrets = import ../configs/secrets.nix;
  wireguard = import ../configs/wireguard.nix;
in
{
  nixpkgs = {
    overlays = [
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
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./framework-hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ../configs/browser.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/games.nix
    ../configs/libvirt.nix
    ../configs/plasma-wayland.nix
    ../configs/user-gui.nix
    ../configs/user.nix
  ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = { canTouchEfiVariables = true; };
    };
  };

  # nixpkgs.config = {
  #   allowUnfree = true;
  #   packageOverrides = pkgs: {
  #     intel-vaapi-driver =
  #       pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  #   };
  # };

  # nixpkgs.localSystem = {
  #   gcc.arch = "alderlake";
  #   gcc.tune = "alderlake";
  #   system = "x86_64-linux";
  # };

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-alderlake" ];

  networking = {
    hostName = "framework";
  };

  time.timeZone = "Europe/Berlin";

  programs.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
      strategies = {
        "lazy" = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            { temp = 0; speed = 15; }
            { temp = 50; speed = 15; }
            { temp = 65; speed = 25; }
            { temp = 70; speed = 35; }
            { temp = 75; speed = 50; }
            { temp = 85; speed = 100; }
          ];
        };
      };
    };
  };

  hardware = {
    keyboard.qmk.enable = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    openrazer = {
      enable = true;
      users = [ "alex" ];
    };

    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver intel-vaapi-driver ];
    };
    pulseaudio.enable = false;
  };

  # Bring in some audio
  security.rtkit.enable = true;
  # rtkit is optional but recommended
  services = {
    # foldingathome.enable = true;
    power-profiles-daemon.enable = true;
    colord.enable = true;

    fwupd.enable = true;

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
          path = "/home/alex/storage";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs =
        "--stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_ed25519";
      paths = [ "/home/alex" "/var/lib" ];
      repo = secrets.borg-repo;
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: "/home/alex/" + x) be.borg-exclude;
    };

    tailscale.enable = true;
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 40960;

  environment.systemPackages = with pkgs.unstable; [
    psensor
    veracrypt
    gnumake
    pkg-config
    libftdi
    libusb1
    gcc
    intel-gpu-tools
    msr-tools
    quota
    mergerfs
    snapraid
    gparted
    homebank
    # fahviewer
    # fahcontrol
  ];

  # Set up deep sleep + hibernation
  swapDevices = [{
    device = "/swapfile";
    size = 64 * 1024;
  }];

  # Partition swapfile is on (after LUKS decryption)
  boot.resumeDevice = "/dev/disk/by-uuid/5549d49d-165e-4a45-973e-6a32a63e31be";

  # Resume Offset is offset of swapfile
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=190937088" ];

  # Suspend-then-hibernate everywhere
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=2m
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=60m";

  system.stateVersion = "24.05";
}
