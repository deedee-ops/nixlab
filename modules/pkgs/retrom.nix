{
  lib,
  stdenv,
  rustPlatform,
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
  perl,
  pkg-config,
  pnpm_9,
  protobuf,
  webkitgtk_4_1,
}:
let
  pname = "retrom";
  version = "0.4.10";
  src = fetchFromGitHub {
    owner = "JMBeresford";
    repo = pname;
    rev = "retrom-v${version}";
    hash = "sha256-M6CEikK8JPAlCX//eXyLVK9rB/0Odu4pJy/2kAVBr40=";
  };
  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    hash = "sha256-Ycw7NMA048oKjA5z7XJVEfxaFZI3E7UALbgYl5W1yqg=";
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
    outputHash = "sha256-U9V5xdHVdk63yUd6ainjLJe5tCHJbzD8JeZG/VMGr0o=";
  };
in
rustPlatform.buildRustPackage rec {
  inherit
    pname
    version
    src
    pnpmDeps
    ;

  cargoHash = "sha256-njoDxrJm0WXUu554rDPNbCojwv/llwrv2GIEfA+9xDE=";

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

  postFixup = ''
    wrapProgram "$out/bin/retrom" \
      --set GIO_MODULE_DIR "${glib-networking}/lib/gio/modules/" \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1
  '';

  meta = {
    description = "A centralized game library/collection management service with a focus on emulation.";
    homepage = "https://github.com/JMBeresford/retrom";
    license = with lib.licenses; [ gpl3 ];
    mainProgram = "retrom";
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = lib.platforms.linux;
  };
}
