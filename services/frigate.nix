{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
in
{
  services = {
    nginx = {
      virtualHosts = {
        "frigate.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          basicAuthFile = config.sops.secrets.frigate-htpasswd.path;
        };
      };
    };

    frigate = {
      enable = true;
      package = pkgs.unstable.frigate;
      hostname = "frigate.szczepan.ski";

      settings = {
        logger = {
          default = "info";
          logs = {
            "frigate.event" = "debug";
          };
        };

        mqtt.enabled = false;

        detectors.cpu1 = {
          type = "cpu";
          num_threads = 4;
        };

        cameras = {
          # home = {
          #   ffmpeg.inputs = [{
          #     path = "rtsp://admin:REMOVED@192.168.178.34:554/H.264";
          #     # input_args = "preset-rtsp-restream";
          #     # roles = [ "record" "detect" ];
          #     roles = [ "record" ];
          #   }];

          #   record = {
          #     enabled = true;
          #     retain = {
          #       days = 7;
          #       mode = "all";
          #     };
          #     # events = {
          #     #   retain = {
          #     #     default = 14;
          #     #   };
          #     # };
          #   };
          # };

          garage = {
            ffmpeg.inputs = [{
              path = "rtsp://admin:REMOVED@192.168.178.42:554/H.264";
              # input_args = "preset-rtsp-restream";
              # roles = [ "record" "detect" ];
              roles = [ "record" ];
            }];

            record = {
              enabled = true;
              retain = {
                days = 7;
                mode = "all";
              };
              events = {
                retain = {
                  default = 14;
                };
              };
            };
          };

        };
      };
    };
  };
}
