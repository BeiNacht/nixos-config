{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  services = {
    frigate = {
      enable = true;
      package = unstable.pkgs.frigate;
      hostname = "100.64.0.7";

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

        # ffmpeg.hwaccel_args = "preset-vaapi";

        cameras = {
          home = {
            ffmpeg.inputs = [{
              path = "rtsp://admin:REMOVED@192.168.178.34:554/H.264";
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
              # events = {
              #   retain = {
              #     default = 14;
              #   };
              # };
            };

          };
        };
      };
    };
  };
}
