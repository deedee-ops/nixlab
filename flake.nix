{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    disko.url = "github:nix-community/disko";
    deploy-rs.url = "github:serokell/deploy-rs";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
