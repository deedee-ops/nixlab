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
      hash = "sha256-6eUsvNMQoJ5TUWPkOlmcJqdmxaXoBStnhiXiya+0nV8=";
    };

    cargoHash = "sha256-6+drbq9dQ5/Atzoz9VPS4BoYEPeM5OqPXUuM1AXP72g=";

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
