with import <nixpkgs> { };

(
  let
    idasen = pkgs.python3Packages.buildPythonPackage rec {
      name = "idasen";
      version = "v0.7.1";

      src = pkgs.fetchFromGitHub {
        owner = "newAM";
        repo = "${name}";
        rev = "${version}";
        #sha256 = "1ibrwal80z27c2mh9hx85idmzilx6cpcmgc15z3lyz57bz0krigb";
      };

      meta = {
        homepage = "https://github.com/newAM/idasen";
        description = "This is a command line interface written in python to control the Idasen via bluetooth from a desktop computer.";
        license = stdenv.lib.licenses.gpl3Plus;
        maintainers = with maintainers; [ newAM ];
      };
    };

  in
  pkgs.python3.buildEnv.override rec {
    extraLibs = with pkgs.python3Packages; [ numpy toolz vpn-slice ];
    propagatedBuildInputs = with pkgs.python3Packages; [ setproctitle ];
  }
).env
