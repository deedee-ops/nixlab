{
  system,
  lib,
  makeRustPlatform,
  fenix,
  fetchFromGitHub,
}:
let
  # nix build .#nixlab.nping

  # renovate: datasource=github-releases depName=hanshuaikang/Nping versioning=semver-coerced
  rev = "v0.6.1";
in
(makeRustPlatform {
  inherit (fenix.packages."${system}".stable) cargo rustc;
}).buildRustPackage
  {
    pname = "nping";
    version = builtins.replaceStrings [ "v" ] [ "" ] rev;
    src = fetchFromGitHub {
      inherit rev;
      owner = "hanshuaikang";
      repo = "Nping";
      hash = "sha256-Ljm6aldP0+E7X3ECoUXcMWTTC41gPT3n/v/NmjB3DWc=";
    };

    cargoHash = "sha256-pxydcSvAc2650tjEVoEEvTeFANqdYpg+ht/aLiGp4Z0=";

    doCheck = false;

    meta = {
      description = "Nping mean NB Ping, A Ping Tool in Rust with Real-Time Data and Visualizations";
      homepage = "https://github.com/hanshuaikang/Nping";
      license = with lib.licenses; [ mit ];
      mainProgram = "nping";
      maintainers = with lib.maintainers; [ ajgon ];
      platforms = lib.platforms.linux;
    };
  }
