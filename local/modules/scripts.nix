_: {
  perSystem =
    { pkgs, ... }:
    rec {
      packages = {
        bootstrap = pkgs.stdenv.mkDerivation {
          name = "bootstrap";
          version = "0.0.1";
          src = ../scripts;
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin

            cp $src/bin/bootstrap.sh $out/bin/bootstrap
            cp $src/secrets.tar.gz.enc $out/
          '';
        };
        build-base-vm = pkgs.writeScriptBin "build-base-vm" (
          builtins.readFile ../scripts/bin/build-base-vm.sh
        );
        cache-packages = pkgs.writeScriptBin "cache-packages" (
          builtins.readFile ../scripts/bin/cache-packages.sh
        );
        disko-install = pkgs.writeScriptBin "disko-install" (
          builtins.replaceStrings [ "@@ASSETS_DIR@@" ] [ "${../../assets}" ] (
            builtins.readFile ../scripts/bin/disko-install.sh
          )
        );
      };

      apps = {
        bootstrap = {
          type = "app";
          program = "${packages.bootstrap}/bin/bootstrap";
        };
        build-base-vm = {
          type = "app";
          program = "${packages.build-base-vm}/bin/build-base-vm";
        };
        cache-packages = {
          type = "app";
          program = "${packages.cache-packages}/bin/cache-packages";
        };
        disko-install = {
          type = "app";
          program = "${packages.disko-install}/bin/disko-install";
        };
      };
    };
}
