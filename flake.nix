{
  description = "Your new nix config";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    impermanence.url = "github:nix-community/impermanence";

    # nixos-cosmic = {
    #   url = "github:lilyinstarlight/nixos-cosmic";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };
  };

  outputs =
    { self
    , chaotic
    , fw-fanctrl
    , home-manager
    , nixos-hardware
    , nixpkgs-stable
    , nixpkgs-unstable
    , sops-nix
    # , nixos-cosmic
    , impermanence
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      nixpkgs = nixpkgs-unstable;

      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # cosmic-modules = [
      #   {
      #     nix.settings = {
      #       substituters = [ "https://cosmic.cachix.org/" ];
      #       trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
      #     };
      #   }
      #   nixos-cosmic.nixosModules.default
      # ];
    in
    {
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            impermanence.nixosModules.impermanence
            chaotic.nixosModules.default # OUR DEFAULT MODULE
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-cpu-amd-zenpower
            nixos-hardware.nixosModules.common-pc-ssd
            sops-nix.nixosModules.sops
            ./machine/desktop/configuration.nix
          ];
        };

        framework = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            fw-fanctrl.nixosModules.default
            ./machine/framework/configuration.nix
            chaotic.nixosModules.default # OUR DEFAULT MODULE
          ];
        };

        vps-arm = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./machine/vps-arm/configuration.nix
          ];
        };

        mini = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./machine/mini/configuration.nix
          ];
        };

        nixos-virtualbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            sops-nix.nixosModules.sops
            ./machine/nixos-virtualbox/configuration.nix
          ];
        };
      };
    };
}
