{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "cascadia-code";
  version = "2404.23";

  src = ./fonts;

  installPhase = ''
    runHook preInstall

    install -Dm644 *.ttf -t $out/share/fonts/truetype

    runHook postInstall
  '';

  meta = {
    description = "Icomoon Feather font.";
    homepage = "https://icomoon.io/";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
