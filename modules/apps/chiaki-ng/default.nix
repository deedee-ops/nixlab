{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.chiaki-ng;

  # hack, to enable touchpad click while streaming.
  # Normally Linux hijacks touchpad, and treats it as a mouse, mapping touchpad click to left-click.
  # However chiaki doesn't support left-click, but lucky for us - interprets right-click as touchpad.
  # So swapping left-click with right-click makes touchpad behaving as expected, while also small portion
  # of touchpad (at the bottom) still behaving like left-click, to ease navigation on chiaki itself.
  padRemapper = pkgs.writeShellScriptBin "input-remapper" ''
    pad_name="Wireless Controller Touchpad"
    while true; do
      sleep 5
      if ${lib.getExe pkgs.xorg.xinput} | grep -q "$pad_name"; then
        pad_id="$(${lib.getExe pkgs.xorg.xinput} | grep 'Wireless Controller Touchpad' | sed -E 's@.*id=([0-9]+).*@\1@g')"

        if [[ "$(${lib.getExe pkgs.xorg.xinput} get-button-map "$pad_id")"] == 1* ]]; then
          ${lib.getExe pkgs.xorg.xinput} set-button-map "$pad_id" 3 2 1 4 5 6 7
        fi
      fi
    done
  '';
in
{
  options.myHomeApps.chiaki-ng = {
    enable = lib.mkEnableOption "chiaki-ng";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Chiaki package to be used";
      default = pkgs.chiaki-ng;
    };
    configFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing chiaki-ng config.";
      default = "home/apps/chiaki-ng/config";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.configFileSopsSecret}" = { };

    xsession.initExtra = lib.mkAfter ''
      ${lib.getExe padRemapper} &
    '';

    home = {
      packages = [ cfg.package ];
    };

    systemd.user.services.init-chiaki-ng = lib.mkHomeActivationAfterSops "init-chiaki-ng" ''
      mkdir -p ${config.xdg.configHome}/Chiaki ${config.xdg.dataHome}/Chiaki
      # @todo ugly hack to make binary available for kiosk
      cp ${lib.getExe cfg.package} ${config.xdg.dataHome}/Chiaki/chiaki-start
      cp ${
        config.sops.secrets."${cfg.configFileSopsSecret}".path
      } ${config.xdg.configHome}/Chiaki/Chiaki.conf
      chmod 700 ${config.xdg.dataHome}/Chiaki/chiaki-start
    '';
  };
}
