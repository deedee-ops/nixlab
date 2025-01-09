{
  lib,
  stdenv,
  fetchFromGitHub,
  curl,
  imagemagick,
  libzip,
  pkg-config,
  SDL,
  SDL_image,
}:

stdenv.mkDerivation {
  pname = "linapple";
  version = "2.3";

  src = fetchFromGitHub {
    owner = "linappleii";
    repo = "linapple";
    rev = "eb1f22e6093bc95cc93756fb905180d01c28656b";
    hash = "sha256-KwUOmjGnfjsQomtn2So/SLoe3XSStD+TbWPsxJaaGcc=";
  };

  nativeBuildInputs = [
    curl
    imagemagick
    libzip
    pkg-config
    SDL
    SDL_image
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/linapple $out/etc/linapple
    install -D --target-directory "$out/bin" build/bin/linapple
    install -D --target-directory "$out/share/linapple" build/share/linapple/Master.dsk
    install -D --target-directory "$out/etc/linapple" build/etc/linapple/linapple.conf

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/linappleii/linapple/";
    description = "An Apple IIe emulator";
    license = with lib.licenses; [ gpl2Only ];
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = lib.platforms.linux;
    mainProgram = "linapple";
  };
}
