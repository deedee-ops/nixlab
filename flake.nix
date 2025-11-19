rec {
  description = "Description for the project";

  nixConfig = {
    substituters = [
      "https://s3.ajgon.casa/nix?priority=30"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "homelab:mM9UlYU+WDQSnxRfnV0gNcE+gLD/F9nkGIz97E22VeU="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    extra-substituters = [
      "https://cache.garnix.io"
      "https://deploy-rs.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = true;
    connect-timeout = 5;
    warn-dirty = false;
    download-buffer-size = 524288000;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    headplane = {
      url = "github:tale/headplane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixos-stable.follows = "nixpkgs-stable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ucodenix = {
      url = "github:e-tho/ucodenix";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # https://nixos.zulipchat.com/#narrow/stream/419910-flake-parts/topic/Overriding.20.60lib.60.20in.20flake-parts
      specialArgs = {
        inherit nixConfig;

        lib = inputs.nixpkgs.lib.extend (_: _: (import ./lib/system.nix { inherit inputs nixConfig; }));
      };
    in
    flake-parts.lib.mkFlake { inherit inputs specialArgs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./local
        ./machines
      ];
    }
    // {
      nixlab = {
        inherit nixConfig;

        system = ./modules/system;
        hardware = {
          incus = ./modules/hardware/incus.nix;
          ms-01 = ./modules/hardware/ms-01.nix;
          vm-amd = ./modules/hardware/vm-amd.nix;
        };
      };
    };
}
