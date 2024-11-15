# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # pythonPackagesExtensions =
    #   prev.pythonPackagesExtensions
    #   ++ [
    #     (
    #       python-final: python-prev: {
    #         numpy = python-prev.numpy.overridePythonAttrs (oldAttrs: {
    #           # disabledTests = oldAttrs.disabledTests ++ ["test_validate_transcendentals"];
    #           postPatch = ''
    #             rm numpy/core/tests/test_cython.py
    #             rm numpy/core/tests/test_umath_accuracy.py
    #             rm numpy/core/tests/test_*.py
    #           '';
    #           doCheck = false;
    #           doInstallCheck = false;
    #           dontCheck = true;
    #           disabledTests = [
    #             "test_math"
    #             "test_umath_accuracy"
    #             "test_validate_transcendentals"
    #           ];
    #         });
    #       }
    #     )
    #   ];
    # python = prev.python.override {
    #   packageOverrides = python-final: python-prev: {
    #     numpy = python-prev.numpy.overridePythonAttrs (oldAttrs: {
    #       disabledTests = oldAttrs.disabledTests ++ ["test_umath_accuracy" "TestAccuracy::test_validate_transcendentals" "test_validate_transcendentals"];
    #     });
    #   };
    # };

    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # linuxPackages_6_11 = final.pkgs.linuxPackagesFor (final.pkgs.linuxPackages_6_11.override {
    #   argsOverride = rec {
    #     src = final.pkgs.fetchurl {
    #       url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
    #       sha256 = "0wwv8jaipx352rna6bxj6jklmnm4kcikvzaag59m4zf1mz866wh5";
    #     };
    #     version = "6.11.3";
    #     modDirVersion = "6.11.3";
    #   };
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
