{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  sshKeys = import ./ssh-keys.nix;
in {
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 10;
        enableCryptodisk = true;
        useOSProber = true;
      };
    };

    tmp = {
      useTmpfs = lib.mkDefault true;
      cleanOnBoot = true;
    };
    consoleLogLevel = 0;
    kernel.sysctl = {"vm.max_map_count" = 262144;};
    supportedFilesystems = ["btrfs"];

    initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = sshKeys.initrd;
          hostKeys = ["/persist/pre_boot_ssh_key"];
        };
      };
      systemd.services = {
        restore-root = {
          description = "Restore blank /root subvolume in initrd";
          wantedBy = ["initrd.target"];
          script = ''
            mkdir -p /mnt

            # Mount the btrfs root so we can manipulate subvolumes.
            mount -o subvol=/ /dev/mapper/lvm-root /mnt

            # Remove subvolumes under /root f irst to allow deleting /root.
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

            # Unmount and continue boot.
            umount /mnt
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            # Environment = "PATH=${lib.makeBinPath [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux]}";
          };
          path = [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux];
        };
      };
    };
  };
}
