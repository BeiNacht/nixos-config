{ pkgs, ... }:
{
  users.extraGroups.vboxusers.members = [ "alex" ];

  virtualisation = {
    virtualbox.host ={
      enable = true;
      enableExtensionPack = true;
    };

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [ proot virtiofsd ];
}
