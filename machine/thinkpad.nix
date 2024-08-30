{ config, pkgs, lib, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
in
{
  imports =
    [
      <nixos-hardware/lenovo/thinkpad/x1-extreme>
      /etc/nixos/hardware-configuration.nix
      ../configs/common.nix
      ../configs/docker.nix
      ../configs/libvirt.nix
      ../configs/plasma.nix
      ../configs/user-gui.nix
      ../configs/user.nix
    ];

  boot = {
    # initrd = {
    #   preLVMCommands = lib.mkBefore 400 "sleep 1";
    #   availableKernelModules = [ "e1000e" ];
    #   systemd.enable = true;
    #   luks.forceLuksSupportInInitrd = true;
    #   network = {
    #     enable = true;
    #     ssh = {
    #       enable = true;
    #       port = 22;
    #       authorizedKeys = [
    #         "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPSzeNjfkz7/B/18TcJxxmNFUhvTKoieBcexdzebWH7oncvyBXNRJp8vAqSIVFLzz5UUFQNFuilggs8/N48U84acmFOxlbUmxlkf8KZgeB/G6uQ8ncQh6M1HNNPH+9apTURgfctr7eEZe9seLIEBISQLXB2Sf3F1ogfDj25S8kH9RM4wM1/jDFK5IecWHScKxwQPmCoXeGE1LEJq6nkQLXMDsWhSihtWouaTxSR0p7/wp/Rqt/hzLEWj8e3+qLMc5JrrdaWksupUCysme7CnSfGSzNUv9RKiRCTFofYPT9tbRn5JzdpQ55v22S6OvmmXUHjST1MOzI8MpVPZCCqd/ZQ1E+gErFiMwjG4sn/xxdPK9/jbQaXMjLklbKtR+C5090Ew2u2kj78jqGk/8COhF1MXh/9qjcG+C51uD1AS9d410kfjPwkaUt4U2KktDMQ942nWywrvIWM0Gt2kgDLYotsy/70q/aTJ8bvaCoWoDOGmpWcyNNBalz4OYYGI2Z0WHrVTs0FpzSk/XeQz0OLkmueoh5GDGd8zrfO6Nf5LWI17aWGRePTpQP5mJIg6jC3j8/QVrthEP6QyIIkZsnfsmvSiMWVfXqEy1BxVlu3T6aLffaj679KCsxY+mx5mTH2hwd4ZdbSI4F0GCIt+WGaFhHs2V3ZQitoEZuraRPEc4HGw== alexander@szczepan.ski"
    #         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
    #       ];
    #       hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    #     };
    #     postCommands = let
    #       # I use a LUKS 2 label. Replace this with your disk device's path.
    #       disk = "/dev/disk/by-label/nixos";
    #     in ''
    #       echo 'cryptsetup open ${disk} root --type luks && echo > /tmp/continue' >> /root/.profile
    #       echo 'starting sshd...'
    #     '';
    #   };
    #   postDeviceCommands = ''
    #     echo 'waiting for root device to be opened...'
    #     mkfifo /tmp/continue
    #     cat /tmp/continue
    #   '';
    # };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      	editor = false;
      };
      efi = {
        canTouchEfiVariables = false;
      };
    };
    plymouth.enable = true;
  };

  # boot.initrd.luks.devices."nixos".preLVM = true;

  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.

  networking = {
    hostName = "thinkpad";
    useDHCP = false;
    firewall = { enable = false; };
    interfaces.enp0s31f6.useDHCP = true;
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.8/24" ];
        privateKey = secrets.wireguard-thinkpad-private;

        peers = [{
          publicKey = secrets.wireguard-vps-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "207.180.220.97:51820";
          persistentKeepalive = 25;
        }];
      };
    };
  };

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "latarcyrheb-sun32";
    keyMap = "us";
  };

  # Enable sound.

  # hardware.pulseaudio = {
  #   enable = true;
  #   support32Bit = true;
  #   daemon = {
  #     config = {
  #       avoid-resampling = "yes";
  #     };
  #   };
  #   configFile = pkgs.runCommand "default.pa" { } ''
  #     sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
  #       ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
  #   '';
  # };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services = {
    thinkfan = {
      enable = true;
      levels = [
        [ 0 0 67 ]
        [ 1 65 75 ]
        [ 2 73 80 ]
        [ 3 78 85 ]
        [ 4 83 90 ]
        [ 6 88 95 ]
        [ 7 93 32767 ]
      ];
    };
    # xserver = {
    #   enable = true;
    #   displayManager.sddm.enable = true;
    #   desktopManager.plasma5.enable = true;
    # };
    # xrdp = {
    #   enable = true;
    #   defaultWindowManager = "startplasma-x11";
    # };
    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;
    tlp.enable = false;
    # tlp = {
    #   enable = true;
    #   settings = {
    #     START_CHARGE_THRESH_BAT0 = 80;
    #     STOP_CHARGE_THRESH_BAT0 = 90;
    #   };
    # };
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  powerManagement.powertop.enable = true;

  system.stateVersion = "23.11";
}
