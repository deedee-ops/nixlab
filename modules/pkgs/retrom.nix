{
  system,
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
  rev = "v0.7.24";

  pname = "retrom";
  version = builtins.replaceStrings [ "v" ] [ "" ] rev;
  src = fetchFromGitHub {
    inherit rev;

    owner = "JMBeresford";
    repo = pname;
    hash = "sha256-BSzwC4FxvQxSBAsGUidb5fd7XyIy61PQK6caGWptL8s="; # 1
  };
  pnpmDeps = pnpm_10.fetchDeps {
    inherit pname version src;
    hash = "sha256-A5a8+pItxIfr/ShPibyKgLMdEYzHRKg5FmrFNvJDPh0="; # 2
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
    ];

    buildPhase = ''
      runHook preBuild
      # patch out cargo build, we'll do it in next step
      sed -E -i"" 's@"dependsOn":(.*), "cargo-build-transit"@"dependsOn":\1@g' turbo.json

      pnpm turbo --filter @retrom/client-web build:desktop
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/packages/client/web
      mkdir -p $out/packages/codegen
      mkdir -p $out/plugins/retrom-plugin-config/
      mkdir -p $out/plugins/retrom-plugin-installer/
      mkdir -p $out/plugins/retrom-plugin-standalone/

      cp -r packages/client/web/dist $out/packages/client/web/
      cp -r packages/codegen/dist $out/packages/codegen/
      cp -r plugins/retrom-plugin-config/dist $out/plugins/retrom-plugin-config/
      cp -r plugins/retrom-plugin-installer/dist $out/plugins/retrom-plugin-installer/
      cp -r plugins/retrom-plugin-standalone/dist $out/plugins/retrom-plugin-standalone/
      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-Ivlnlbk/BOfh+gopI5XCopoZKsNoUhxg/yViJXqmzxI="; # 4
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

    cargoHash = "sha256-XQPvnjJOYT102Keoql8m3jzvf9IkJenuwHU+rosPq5E="; # 3
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
