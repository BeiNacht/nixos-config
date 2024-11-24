{pkgs, ...}: {
  users.extraGroups.vboxusers.members = ["alex"];

  virtualisation = {
    virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
  };
}
