{pkgs, ...}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/aniworld"
      ];
    };
  };

  systemd.services.aniworld = {
    description = "Run aniworld from a managed Python virtual environment";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    path = [pkgs.python313 pkgs.ffmpeg];

    script = ''
      set -euo pipefail

      venv_dir="/var/lib/aniworld/.venv"

      if [ ! -x "$venv_dir/bin/python" ]; then
        python -m venv "$venv_dir"
      fi

      source "$venv_dir/bin/activate"

      pip install --upgrade pip
      pip install --upgrade aniworld

      exec aniworld -w -wE
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      User = "alex";
      Group = "users";
      StateDirectory = "aniworld";
      WorkingDirectory = "/var/lib/aniworld";
    };
  };
}
