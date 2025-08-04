{
  lib,
  fetchFromGitHub,
  python3Packages,
  dbusEnabled ? true,
}:

with python3Packages;
buildPythonPackage rec {
  pname = "lnxlink";
  version = "2025.6.0";

  src = fetchFromGitHub {
    owner = "bkbilly";
    repo = "lnxlink";
    rev = "${version}";
    hash = "sha256-Ov3o3Ue7HEDnb58XO7dhKOpItffYxRdi8vE3EUPwgOo=";
  };

  postPatch = ''
    sed -i"" -E 's@requires = .*@requires = ["setuptools", "wheel"]@g' pyproject.toml
  '';

  format = "pyproject";
  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    distro
    inotify
    paho-mqtt
    psutil
    pyaml
    requests
  ]
  ++ lib.optionals dbusEnabled [
    pygobject3
    dasbus
  ];

  meta = {
    homepage = "https://github.com/bkbilly/lnxlink";
    description = "Effortlessly manage your Linux machine using MQTT.";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ ajgon ];
    platforms = lib.platforms.linux;
    mainProgram = "lnxlink";
  };
}
