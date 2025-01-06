{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };
  };

  time.timeZone = "Europe/Berlin";

  boot = {
    initrd = {
      enable = true;
      postResumeCommands = lib.mkAfter ''
        mkdir -p /mnt
        # We first mount the btrfs root to /mnt
        # so we can manipulate btrfs subvolumes.
        mount -o subvol=/ /dev/sda2 /mnt

        # While we're tempted to just delete /root and create
        # a new snapshot from /root-blank, /root is already
        # populated at this point with a number of subvolumes,
        # which makes `btrfs subvolume delete` fail.
        # So, we remove them first.
        #
        # /root contains subvolumes:
        # - /root/var/lib/portables
        # - /root/var/lib/machines
        #
        # I suspect these are related to systemd-nspawn, but
        # since I don't use it I'm not 100% sure.
        # Anyhow, deleting these subvolumes hasn't resulted
        # in any issues so far, except for fairly
        # benign-looking errors from systemd-tmpfiles.
        btrfs subvolume list -o /mnt/root |
        cut -f9 -d' ' |
        while read subvolume; do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "/mnt/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete /mnt/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /mnt/root-blank /mnt/root

        # Once we're done rolling back to a blank snapshot,
        # we can unmount /mnt and continue on the boot process.
        umount /mnt
      '';
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "nixos-virtualbox"; # Define your hostname.
  };

  nix.settings = {
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "gccarch-znver3"
    ];
    trusted-substituters = ["https://ai.cachix.org"];
    trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];
  };

  # nixpkgs.localSystem = {
  #   gcc.arch = "znver3";
  #   gcc.tune = "znver3";
  #   system = "x86_64-linux";
  # };

  programs.nix-ld.enable = true;

  services = {
    # k3s = {
    #   enable = true;
    #   role = "server";
    # };
  };

  system.stateVersion = "24.11";
}
