{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  be = import ../configs/borg-exclude.nix;
  secrets = import ../configs/secrets.nix;
  wireguard = import ../configs/wireguard.nix;
in
{
  imports = [
    <nixos-hardware/framework/13-inch/12th-gen-intel>
    <home-manager/nixos>
    /etc/nixos/hardware-configuration.nix
    ../configs/browser.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/games.nix
    ../configs/libvirt.nix
    ../configs/plasma-wayland.nix
    ../configs/user-gui.nix
    ../configs/user.nix
    /home/alex/Workspace/fw-fanctrl-nix/service.nix
  ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi = { canTouchEfiVariables = true; };
    };
    plymouth.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      intel-vaapi-driver =
        pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };
  };

  # nixpkgs.localSystem = {
  #   gcc.arch = "alderlake";
  #   gcc.tune = "alderlake";
  #   system = "x86_64-linux";
  # };

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-alderlake" ];

  networking = {
    hostName = "framework";
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.7/24" ];
        privateKey = secrets.wireguard-framework-private;

        peers = [{
          publicKey = wireguard.wireguard-vps-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "old.szczepan.ski:51820";
          persistentKeepalive = 25;
        }];
      };
    };
  };

  time.timeZone = "Europe/Berlin";

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
    power-profiles-daemon.enable = true;
    colord.enable = true;

    fwupd.enable = true;

    fw-fanctrl = {
      enable = true;
      configJsonPath = "/home/alex/nixos-config/config.json";
    };

    # displayManager.autoLogin = {
    #   enable = true;
    #   user = "alex";
    # };

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

  environment.systemPackages = with unstable.pkgs; [
    # rustdesk
    # cinnamon.warpinator
    psensor
    veracrypt
    gnumake
    pkg-config
    libftdi
    libusb1
    gcc
    # coreboot-toolchain.arm
    intel-gpu-tools
    msr-tools
    quota
    homebank
    (import ("/home/alex/Workspace/fw-ectool/default.nix"))
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

  home-manager.users.alex.services.barrier.client = {
    enable = true;
    enableCrypto = false;
    name = "framework";
    server = "192.168.0.168:24800";
  };

  system.stateVersion = "24.05";
}
