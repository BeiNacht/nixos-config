{config, ...}: {
  sops = {
    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
      };
    };
  };

  services = {
    borgbackup.jobs.all = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-key.path}";
      };
      extraCreateArgs = "--stats --verbose --checkpoint-interval=600 --exclude-caches";
      extraPruneArgs = [
        "--save-space"
        "--stats"
      ];
      extraCompactArgs = [
        "--cleanup-commits"
      ];
      environment = {
        BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_ed25519";
        BORG_BASE_DIR = "/persist/borg";
        BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
      };
      readWritePaths = ["/persist/borg"];
      paths = ["/home/alex" "/persist"];
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/home/alex/.config/Nextcloud/logs"
        "/home/alex/.local/share/baloo" # KDE File indexer
        # ".local/share/libvirt/images"
        "/home/alex/.local/share/Steam"
        "/home/alex/.local/share/Trash"
        "/home/alex/Downloads"
        "/home/alex/Games"
        "/home/alex/Nextcloud"
        "/home/alex/NextcloudEncrypted" # Decrypted File from Nextcloud
        "/home/alex/VirtualBox VMs"
        "/home/alex/shared"

        "/persist/borg"
        "/persist/var/lib/libvirt"
      ];
    };
  };
}
