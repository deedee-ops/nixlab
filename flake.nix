{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nvf.url = "github:notashelf/nvf";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      inputs.import-tree.matchNot ".*/features/.*/.*/.*" ./modules
    );
}
