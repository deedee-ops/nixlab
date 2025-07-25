{
  system,
  lib,
  faketty,
  stdenv,
  makeRustPlatform,
  fenix,
  fetchFromGitHub,
  cargo-tauri,
  glib,
  glib-networking,
  gnused,
  gtk3,
  jq,
  libsoup_3,
  makeWrapper,
  nodejs_22,
  openssl,
  perl,
  pkg-config,
  pnpm_10,
  protobuf,
  webkitgtk_4_1,
  supportNvidia ? false,
}:
let
  # renovate: datasource=github-releases depName=JMBeresford/retrom versioning=semver-coerced
  rev = "v0.7.29";

  pname = "retrom";
  version = builtins.replaceStrings [ "v" ] [ "" ] rev;
  src = fetchFromGitHub {
    inherit rev;

    owner = "JMBeresford";
    repo = pname;
    hash = "sha256-XrcdYGz0Br604QlK811X8od+ugQrVPriokL9X5box9Y="; # 1
  };
  pnpmDeps = pnpm_10.fetchDeps {
    inherit pname version src;
    hash = "sha256-Ulb0FV4Kyk5wfk/A3TvM8F8cuaP6uJTRWhbBY/q9gI0="; # 2
  };

  # Fixed Output Derivation
  # https://phip1611.de/blog/accessing-network-from-a-nix-derivation/
  depsGenerated = stdenv.mkDerivation {
    inherit src pnpmDeps;

    pname = "retrom-deps-generated";
    version = "0.0.0";
    doCheck = false;
    dontFixup = true;

    nativeBuildInputs = [
      pnpm_10.configHook
      gnused
      nodejs_22
      faketty
    ];

    buildPhase = ''
      runHook preBuild
      sed -i"" -E 's@"parallel":(.*)@"parallel":\1"sync":{"applyChanges":true},@' nx.json
      sed -i"" 's@nxCloudId@test@g' nx.json
      faketty pnpm nx build:desktop retrom-client-web
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      find packages -name dist -exec sh -c 'mkdir -p '"$out"'/$(dirname {}); cp -r {} '"$out"'/$(dirname {})/' \;
      find plugins -name dist -exec sh -c 'mkdir -p '"$out"'/$(dirname {}); cp -r {} '"$out"'/$(dirname {})/' \;
      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-/r5U+Y0rRr35UAptBpwKr52Gr76b8w9iw972k6CoBW8="; # 4
  };
in
(makeRustPlatform {
  inherit (fenix.packages."${system}".stable) cargo rustc;
}).buildRustPackage
  rec {
    inherit
      pname
      version
      src
      pnpmDeps
      ;

    cargoHash = "sha256-QLQDj6rz/FJX4Hrb6nFAU8wZwV7cRY4WEpajWen/axA="; # 3
    useFetchCargoVendor = true;

    # buildType = "debug";
    cargoRoot = "packages/client";
    buildAndTestSubdir = cargoRoot;

    tauriBuildFlags = [ "--config tauri.build.conf.json" ];

    nativeBuildInputs = [
      cargo-tauri.hook
      gnused
      jq
      makeWrapper
      nodejs_22
      openssl
      perl
      pkg-config
      pnpm_10.configHook
      protobuf
      depsGenerated
    ];

    buildInputs = [
      glib
      glib-networking
      gtk3
      libsoup_3
      webkitgtk_4_1
    ];

    doCheck = false;

    OPENSSL_NO_VENDOR = 1;
    OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";
    OPENSSL_DIR = "${lib.getDev openssl}";

    postUnpack = ''
      [ ! -f "source/${cargoRoot}/Cargo.lock" ] && cp source/Cargo.lock source/${cargoRoot}
    '';

    preBuild = ''
      cp -r ${depsGenerated}/packages .
      cp -r ${depsGenerated}/plugins .
      jq '. + {"bundle": { "windows": null } } | del(.plugins.updater)' packages/client/tauri.build.conf.json > temp.json
      mv temp.json packages/client/tauri.build.conf.json
    '';

    postInstall = ''
      mv $out/bin/Retrom $out/bin/retrom
      sed -i"" 's@Exec=Retrom@Exec=retrom@g' $out/share/applications/Retrom.desktop
    '';

    postFixup =
      "wrapProgram \"$out/bin/retrom\" --set GIO_MODULE_DIR \"${glib-networking}/lib/gio/modules/\""
      + (lib.optionalString supportNvidia " --set WEBKIT_DISABLE_DMABUF_RENDERER 1");

    meta = {
      description = "A centralized game library/collection management service with a focus on emulation.";
      homepage = "https://github.com/JMBeresford/retrom";
      license = with lib.licenses; [ gpl3 ];
      mainProgram = "retrom";
      maintainers = with lib.maintainers; [ ajgon ];
      platforms = lib.platforms.linux;
    };
  }
