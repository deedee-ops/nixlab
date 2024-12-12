{
  lib,
  python3Packages,
  fetchPypi,
  qt5,
  withQT ? false,
}:
let
  cursedspace = python3Packages.buildPythonPackage rec {
    pname = "cursedspace";
    version = "1.5.2";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-IQQ/gEmNuaedXuG7UiKf0orYhxo2BgHI+RIP+drcKuw=";
    };

    meta = with lib; {
      description = "A python library/framework for TUI application on the basis of the curses package.";
      homepage = "https://vonshednob.cc/cursedspace";
      license = with licenses; [ mit ];
      maintainers = with maintainers; [ ajgon ];
      platforms = platforms.unix;
    };
  };
  pytodotxt = python3Packages.buildPythonPackage rec {
    pname = "pytodotxt";
    version = "2.0.0.post1";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-vb38F4QLGJA9N3hNHFjEn92BJzI9m2I045kqdO6oAxA=";
    };

    buildInputs = [
      python3Packages.setuptools
    ];

    meta = with lib; {
      description = "A tiny library to access todo.txt-like task lists.";
      homepage = "https://vonshednob.cc/pytodotxt/doc/";
      license = with licenses; [ mit ];
      maintainers = with maintainers; [ ajgon ];
      platforms = platforms.unix;
    };
  };
in
python3Packages.buildPythonPackage rec {
  pname = "pter";
  version = "3.19.0";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-9lyRHNM6Y9EgtNPXy6jVn6QjFFs3p1ZpCHl1t20W6bw=";
  };

  buildInputs = [
    python3Packages.docutils
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    cursedspace
    pytodotxt
  ] ++ lib.optionals withQT [ python3Packages.pyqt5 ];

  postFixup = lib.optionalString withQT ''
    wrapProgram "$out/bin/qpter" \
      --prefix QT_QPA_PLATFORM_PLUGIN_PATH : "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins/platforms";
  '';

  meta = with lib; {
    description = "Manage your todo.txt in a commandline user interface (TUI)";
    mainProgram = "pter";
    homepage = "https://vonshednob.cc/pter/";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ ajgon ];
    platforms = platforms.unix;
  };
}
