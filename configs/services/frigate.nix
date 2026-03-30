{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/frigate"
      ];
    };
  };

  services = {
    frigate = {
      enable = false;
      package = pkgs.frigate;
      hostname = "frigate.szczepan.ski";

      settings = {
        logger = {
          default = "info";
          logs = {
            "frigate.event" = "debug";
          };
        };

        mqtt.enabled = false;

        detectors.coral = {
          type = "edgetpu";
          device = "pci";
        };

        record = {
          enabled = true;
          retain = {
            days = 7;
            mode = "all";
          };

          preview = {
            quality = "medium";
          };
          alerts = {
            pre_capture = 5;
            post_capture = 5;
            retain = {
              days = 14;
              mode = "motion";
            };
          };
          detections = {
            pre_capture = 5;
            post_capture = 5;
            # Optional: Retention settings for recordings of detections

            retain = {
              days = 14;
              mode = "motion";
            };
          };
        };

        cameras = {
          outside = {
            ffmpeg.inputs = [
              {
                path = "rtsp://admin:NosferatuCameras@192.168.178.68:554/H.264";
                input_args = "preset-rtsp-restream";
                roles = ["record" "detect"];
                #roles = [ "record" ];
              }
            ];
          };

          bad = {
            ffmpeg.inputs = [
              {
                path = "rtsp://admin:NosferatuCameras@192.168.178.69:554/H.264";
                input_args = "preset-rtsp-restream";
                roles = ["record" "detect"];
                #roles = [ "record" ];
              }
            ];
          };

          wohnzimmer = {
            ffmpeg.inputs = [
              {
                path = "rtsp://admin:NosferatuCameras@192.168.178.34:554/H.264";
                input_args = "preset-rtsp-restream";
                roles = ["record" "detect"];
                #roles = [ "record" ];
              }
            ];
          };

          garage = {
            ffmpeg.inputs = [
              {
                path = "rtsp://admin:STJXSO@192.168.178.32:554/H.264";
                input_args = "preset-rtsp-restream";
                roles = ["record" "detect"];
                #roles = [ "record" ];
              }
            ];
          };
        };
      };
    };
  };

  # systemd.services.frigate = {
  #   # Erweitere Abhängigkeiten
  #   after = ["network.target" "docker.service"];
  #   requires = ["docker.service"];

  #   # Überschreibe Service-Konfiguration
  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = 30;

  #     # Zusätzliche Capabilities
  #     AmbientCapabilities = ["CAP_SYS_ADMIN"];

  #     # Memory/CPU Limits
  #     MemoryMax = "2G";
  #     CPUQuota = "200%";
  #   };

  #   # Zusätzliche Environment Variables
  #   environment = {
  #     FRIGATE_CONFIG_FILE = "/etc/frigate/config.yml";
  #     PYTHONPATH = "/opt/frigate";
  #   };
  # };
}
