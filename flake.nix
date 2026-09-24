{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Chaotic Nyx repository for CachyOS goodies
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # apple-fonts = {
    #   url = "github:Lyndeno/apple-fonts.nix";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };
  };

  outputs = {
    self,
    home-manager,
    nixos-hardware,
    nixpkgs-unstable,
    sops-nix,
    impermanence,
    nix-darwin,
    chaotic,
    ...
  } @ inputs: let
    inherit (self) outputs;
    nixpkgs = nixpkgs-unstable;

    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
    ];

    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Every host shares the same home-manager wiring (single profile, same
    # settings) — this factors that boilerplate out so each host below only
    # has to list what's actually unique to it: system + extra modules.
    mkNixosHost = {
      system,
      hostModules,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs outputs;};
        modules =
          hostModules
          ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = ".nix-backup";
                users.alex = import ./configs/home.nix;
              };
            }
          ];
      };

    mkDarwinHost = {hostModules}:
      nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules =
          hostModules
          ++ [
            home-manager.darwinModules.home-manager
            {
              users.users.alex.home = /Users/alex;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.alex = import ./configs/home.nix;
              };
            }
          ];
      };
  in {
    overlays = import ./overlays {inherit inputs;};

    nixosConfigurations = {
      desktop = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          impermanence.nixosModules.impermanence
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          nixos-hardware.nixosModules.common-cpu-amd-zenpower
          nixos-hardware.nixosModules.common-pc-ssd
          sops-nix.nixosModules.sops
          chaotic.nixosModules.default
          ./machine/desktop.nix
        ];
      };

      framework = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          impermanence.nixosModules.impermanence
          inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
          nixos-hardware.nixosModules.common-pc-ssd
          inputs.sops-nix.nixosModules.sops
          chaotic.nixosModules.default
          ./machine/framework.nix
        ];
      };

      vps-arm = mkNixosHost {
        system = "aarch64-linux";
        hostModules = [
          impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
          ./machine/vps-arm.nix
        ];
      };

      thinkpad = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          impermanence.nixosModules.impermanence
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          inputs.sops-nix.nixosModules.sops
          ./machine/thinkpad.nix
        ];
      };

      mini = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/mini.nix
        ];
      };

      homeserver = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/homeserver.nix
        ];
      };

      nixos-vm = mkNixosHost {
        system = "aarch64-linux";
        hostModules = [
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/nixos-vm/configuration.nix
        ];
      };

      nixos-virtualbox = mkNixosHost {
        system = "x86_64-linux";
        hostModules = [
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/nixos-virtualbox/configuration.nix
        ];
      };

      nixos-vm-fusion = mkNixosHost {
        system = "aarch64-linux";
        hostModules = [
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/nixos-vm-fusion.nix
        ];
      };
    };

    darwinConfigurations = {
      "MacBook" = mkDarwinHost {
        hostModules = [./machine/macbook.nix];
      };

      "MacbookProM1" = mkDarwinHost {
        hostModules = [./machine/macbook.nix];
      };
    };
  };
}
