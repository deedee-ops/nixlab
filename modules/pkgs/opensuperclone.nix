{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  unixtools,
  wrapGAppsHook3,
  gettext,
  gtk3,
  libconfig,
  libusb1,
  libusb-compat-0_1,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "opensuperclone";
  # renovate: datasource=github-releases depName=ISpillMyDrink/OpenSuperClone versioning=semver-coerced
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "ISpillMyDrink";
    repo = "OpenSuperClone";
    rev = "v${finalAttrs.version}";
    hash = "sha256-4+GP2VRG0sA5DeaxFbaI4Ald7vGa1UMxS1i3FCvcM98=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    unixtools.xxd
    wrapGAppsHook3
  ];

  buildInputs = [
    gettext
    gtk3
    libconfig
    libusb1
    libusb-compat-0_1
  ];

  cmakeFlags = [
    (lib.cmakeFeature "GIT_REVISION" finalAttrs.src.rev)
  ];

  meta = {
    description = "Powerful data recovery utility for Linux with many advanced features";
    homepage = "https://github.com/ISpillMyDrink/OpenSuperClone";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = [ "x86_64-linux" ];
  };
})
