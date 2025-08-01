{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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

    # Framework Fancontrol
    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    self,
    chaotic,
    fw-fanctrl,
    home-manager,
    nixos-hardware,
    nixpkgs-unstable,
    sops-nix,
    impermanence,
    nix-darwin,
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
  in {
    overlays = import ./overlays {inherit inputs;};

    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          impermanence.nixosModules.impermanence
          chaotic.nixosModules.default
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          nixos-hardware.nixosModules.common-cpu-amd-zenpower
          nixos-hardware.nixosModules.common-pc-ssd
          sops-nix.nixosModules.sops
          ./machine/desktop.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          fw-fanctrl.nixosModules.default
          impermanence.nixosModules.impermanence
          chaotic.nixosModules.default
          inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
          inputs.sops-nix.nixosModules.sops
          ./machine/framework.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      vps-arm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
          ./machine/vps-arm.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          impermanence.nixosModules.impermanence
          chaotic.nixosModules.default
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          inputs.sops-nix.nixosModules.sops
          ./machine/thinkpad/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      mini = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/mini.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/homeserver.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      nixos-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/nixos-vm/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };

      nixos-virtualbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          ./machine/nixos-virtualbox/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alex = import ./configs/home.nix;
            };
          }
        ];
      };
    };

    darwinConfigurations."MacBook" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./machine/macbook.nix
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
  };
}
