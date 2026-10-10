let
  vhosts = import ../nginx-vhosts.nix;
in {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/audiobookshelf"
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "audiobookshelf.szczepan.ski" = vhosts.proxy "http://127.0.0.1:3006/";
      };
    };

    audiobookshelf = {
      enable = true;
      port = 3006;
    };
  };
}
