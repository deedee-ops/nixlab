{
  lib,
  rustPlatform,
  fetchFromGitHub,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "tod";
  # renovate: datasource=github-releases depName=tod-org/tod versioning=semver-coerced
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "tod-org";
    repo = "tod";
    rev = "v${version}";
    hash = "sha256-AyR6EPyV3596/CSaT6UeqQRloqt8OGxLHzmaaapErl8=";
  };
  cargoHash = "sha256-bCrvy09iagsRblLRsTBAHMuERy+uRrlk9KYd9LS2Rmw=";

  nativeBuildInputs = [ openssl ];

  doCheck = false;

  OPENSSL_NO_VENDOR = 1;
  OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";
  OPENSSL_DIR = "${lib.getDev openssl}";

  meta = {
    description = "An unofficial Todoist command line client written in Rust";
    homepage = "https://github.com/tod-org/tod";
    license = with lib.licenses; [ mit ];
    mainProgram = "tod";
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = lib.platforms.linux;
  };
}
