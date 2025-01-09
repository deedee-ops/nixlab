{
  lib,
  stdenv,
  fetchzip,
  perl,
  libpulseaudio,
  xorg,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kegs";
  version = "1.34";

  src = fetchzip {
    url = "https://kegs.sourceforge.net/kegs.${finalAttrs.version}.zip";
    hash = "sha256-GGXLoosbtgEPw/kevEJlXOYx+c5OEVXRMvlAy0oMGsU=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  patches = [ ./patches/kegs.patch ];

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    libpulseaudio
    xorg.libX11
    xorg.libXext
  ];

  preBuild = ''
    mv vars_x86linux vars
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv xkegs $out/bin

    runHook postInstall
  '';

  meta = {
    homepage = "https://kegs.sourceforge.net/";
    description = "An Apple IIgs emulator";
    license = with lib.licenses; [ gpl1Only ];
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = lib.platforms.linux;
    mainProgram = "xkegs";
  };
})
