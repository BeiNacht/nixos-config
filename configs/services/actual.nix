let
  vhosts = import ../nginx-vhosts.nix;
in {
  services = {
    nginx = {
      virtualHosts = {
        "actual.szczepan.ski" = vhosts.proxy "https://127.0.0.1:5006/";
      };
    };
  };
}
