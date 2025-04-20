{pkgs, ...}: {
  users.extraGroups.libvirtd.members = ["alex"];

  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemu = {
        ovmf.enable = true;
        swtpm.enable = true;
        # vhostUserPackages = [pkgs.virtiofsd];
      };
    };

    spiceUSBRedirection.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      qemu
      # For virt-install
      virt-manager
      # For lsusb
      usbutils
      # quick install vms
      quickemu
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/libvirt"
      ];
    };
  };

  systemd.tmpfiles.rules = let
    firmware = pkgs.runCommandLocal "qemu-firmware" {} ''
      mkdir $out
      cp ${pkgs.qemu}/share/qemu/firmware/*.json $out
      substituteInPlace $out/*.json --replace ${pkgs.qemu} /run/current-system/sw
    '';
  in ["L+ /var/lib/qemu/firmware - - - - ${firmware}"];
}
