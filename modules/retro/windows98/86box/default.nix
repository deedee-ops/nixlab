{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myRetro.windows98;
in
{
  config = lib.mkIf (cfg.enable && cfg.package.pname == "86Box") {
    home = {
      packages = [
        (pkgs.writeShellScriptBin "86Box-retrom" ''
          gamepath="$(dirname "$1")"
          savepath="${cfg.saveStatePath}/$(basename "$1" | sed 's@\.[^.]*$@@g')"

          echo $gamepath
          echo $savepath

          mkdir -p "$savepath"
          [ ! -f "$savepath/savedisk.vhd" ] && cp "$gamepath/savedisk.vhd" "$savepath/savedisk.vhd"
          ln -sf "$savepath/savedisk.vhd" "$gamepath/save.vhd"

          ${lib.getExe cfg.package} -C "$1" -P "$gamepath" -F
        '')
      ];
    };

    myHomeApps.allowUnfree = [ "86Box" ];
  };
}
