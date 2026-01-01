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
  rev = "v0.6.0";
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
      hash = "sha256-WxevLHBvJHAQMU27Xi5XR9+KYfVRsIW3qM/uUu6+ieg=";
    };

    cargoHash = "sha256-rEyqQx2ZhMlS1u6bWeOmjyxLX7AGt+toGi8tsShSvJs=";

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
