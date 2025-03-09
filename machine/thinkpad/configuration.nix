{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # ../../configs/borg.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/libvirtd.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets-mini.yaml;
  };

  boot = {
    initrd = {
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/7f2eb00d-49d8-416f-a742-5af5ce871483";
          preLVM = true;
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # extraModulePackages = with pkgs.linuxPackages_latest; [rtl88x2bu];
  };

  networking = {
    hostName = "thinkpad";
    useDHCP = true;
    firewall = {enable = false;};
    # interfaces = {
    #   br0 = {
    #     useDHCP = true;
    #   };
    # };

    # bridges.br0.interfaces = ["enp3s0"];

    nftables.enable = true;

    wireless = {
      enable = true;
      networks.Skynet-mobil.psk = "***";
      interfaces = ["wlp0s20f3"];
    };
  };

  environment = {
    # systemPackages = with pkgs; [
    #   nyx
    #   snapraid
    #   mergerfs
    # ];
    # persistence."/persist" = {
    #   directories = [
    #     # "/var/lib/docker"
    #     "/var/lib/tor"
    #   ];
    # };
  };

  hardware = {
    enableAllFirmware = true;
  };

  services = {
    locate = {
      prunePaths = ["/mnt" "/nix"];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "powersave";
  };

  system.stateVersion = "24.11";
}
