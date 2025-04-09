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
  # renovate: datasource=github-releases depName=JMBeresford/retrom versioning=semver-coerced
  rev = "v0.7.18";

  pname = "retrom";
  version = builtins.replaceStrings [ "v" ] [ "" ] rev;
  src = fetchFromGitHub {
    inherit rev;

    owner = "JMBeresford";
    repo = pname;
    hash = "sha256-fCK0HksDLIuvlrYz0ATOJm5VN/VTyXpU6ji3/up8aeI=";
  };
  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    hash = "sha256-Cm/1CLZgJe4pYOsK2Eigukbyy1KI9FrcTXVEmJh0N/c=";
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
      pnpm_9.configHook
      gnused
      nodejs
    ];

    buildPhase = ''
      runHook preBuild
      # patch out cargo build, we'll do it in next step
      sed -E -i"" 's@"dependsOn":(.*), "cargo-build-transit"@"dependsOn":\1@g' turbo.json
      sed -E -i"" 's@"build":.*@@g' packages/client/package.json

      pnpm turbo --filter @retrom/client build
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
    outputHash = "sha256-fV7Plq0K2K1prrn4RWI4HsVsJthQRxbsub2T9iN3xqw=";
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

    cargoHash = "sha256-uiQKyHS8Gq+Yku4N0/d4EhqUMEtMkJUxuMHjXGU6Azs=";
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
      nodejs
      openssl
      perl
      pkg-config
      pnpm_9.configHook
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
