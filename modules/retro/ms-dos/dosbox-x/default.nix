{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myRetro.ms-dos;
in
{
  config = lib.mkIf (cfg.enable && cfg.package.pname == "dosbox-x") {
    home.packages = [
      (pkgs.writeShellScriptBin "dosbox-x" ''
        PATH="${lib.makeBinPath [ pkgs.coreutils-full ]}:$PATH"
        cfgpath="$(mktemp -d)/mount.conf"
        gamepath="$(dirname "$1")"
        savepath="${cfg.saveStatePath}/$(basename "$1" | sed 's@\.[^.]*$@@g')"

        echo $cfgpath
        echo $gamepath
        echo $savepath

        mkdir -p "$savepath"
        echo -e "[dosbox]\nsavefile = \"$savepath/state.sav\"\n\n[autoexec]\nmount c \"$1\"\nmount s \"$savepath\"" > "$cfgpath"
        exec ${lib.getExe cfg.package} -conf "${config.xdg.configHome}/dosbox-x/dosbox.conf" -conf "$cfgpath" -conf "$gamepath/dosbox.conf" "$@"
      '')
    ];

    xdg.configFile = {
      "dosbox-x/dosbox.conf".text = ''
        [sdl]
        fullscreen = true

        [dosbox]
        saveremark   = false
        quit warning = false
      '';
    };
  };
}