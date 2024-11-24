rec {
  description = "Description for the project";

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://cache.lix.systems"
      "https://deploy-rs.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = true;
    connect-timeout = 25;
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    home-manager = {
      # url = "github:nix-community/home-manager";
      url = "github:ajgon/home-manager/feat/kubecolor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix = {
      url = "git+https://git.lix.systems/lix-project/lix?ref=main";
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=main";
      inputs.lix.follows = "lix";
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
      # url = "github:danth/stylix";
      url = "github:ajgon/stylix/feat/kubecolor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # https://nixos.zulipchat.com/#narrow/stream/419910-flake-parts/topic/Overriding.20.60lib.60.20in.20flake-parts
      specialArgs = {
        inherit nixConfig;

        lib = inputs.nixpkgs.lib.extend (_: _: (import ./lib { inherit inputs nixConfig; }));
      };
    in
    flake-parts.lib.mkFlake { inherit inputs specialArgs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        ./local
        ./machines
      ];
    }
    // {
      nixlab = {
        system = ./modules/system;
        hardware = {
          incus = ./modules/hardware/incus.nix;
          ms-01 = ./modules/hardware/ms-01.nix;
        };
      };
    };
}
