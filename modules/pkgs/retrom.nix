{
  lib,
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
  nodejs,
  openssl,
  perl,
  pkg-config,
  pnpm_9,
  protobuf,
  webkitgtk_4_1,
  supportNvidia ? false,
}:
let
  # renovate: datasource=github-releases depName=JMBeresford/retrom versioning=regex:^(?<compatibility>retrom-v)(?<major>\d+)(\.(?<minor>\d+))(\.(?<patch>\d+))?$
  rev = "retrom-v0.7.5";

  pname = "retrom";
  version = builtins.replaceStrings [ "retrom-v" ] [ "" ] rev;
  src = fetchFromGitHub {
    inherit rev;

    owner = "JMBeresford";
    repo = pname;
    hash = "sha256-It2upKJKE5FiEPoxzm9ef/Jq7iM7zpzz9Anjx48heQE=";
  };
  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    hash = "sha256-cBoiN5TAiPhuZ9l9vruKaxBwN4SCswoNtiodGQvr7no=";
  };

  # Fixed Output Derivation
  # https://phip1611.de/blog/accessing-network-from-a-nix-derivation/
  bufGenerated = stdenv.mkDerivation {
    inherit src pnpmDeps;

    pname = "retrom-buf-generated";
    version = "0.0.0";
    doCheck = false;
    dontFixup = true;

    nativeBuildInputs = [
      pnpm_9.configHook
      nodejs
    ];

    buildPhase = ''
      runHook preBuild
      pnpm exec buf generate
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir $out
      cp -r packages/client/web/src/generated $out
      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-yAAn0Msxoj6st9Lxy1ieK6AyZ3PvjJEJ3iBlTK5E4Ro=";
  };
in
(makeRustPlatform {
  inherit (fenix.packages.x86_64-linux.stable) cargo rustc;
}).buildRustPackage
  rec {
    inherit
      pname
      version
      src
      pnpmDeps
      ;

    cargoHash = "sha256-QHdg8rzB2gKvJkhtNKdAbunDf5Pb9Ys4d/VrzjS59lk=";

    # buildType = "debug";
    cargoRoot = "packages/client";
    buildAndTestSubdir = cargoRoot;

    tauriBuildFlags = [ "--config tauri.build.conf.json" ];

    nativeBuildInputs = [
      cargo-tauri.hook
      gnused
      jq
      makeWrapper
      nodejs
      openssl
      perl
      pkg-config
      pnpm_9.configHook
      protobuf
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
      cp -r ${bufGenerated}/generated packages/client/web/src/
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
