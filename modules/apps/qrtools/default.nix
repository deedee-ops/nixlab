{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.qrtools;
in
{
  options.myHomeApps.qrtools = {
    enable = lib.mkEnableOption "qrtools";
    qrcpPort = lib.mkOption {
      type = lib.types.port;
      description = "Port used for qrcp send and receive.";
      default = 55555;
    };
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      qrsend = "${lib.getExe pkgs.qrcp} -i ${osConfig.mySystem.networking.rootInterface} -p ${builtins.toString cfg.qrcpPort} send";
      qrrecv = "${lib.getExe pkgs.qrcp} -i ${osConfig.mySystem.networking.rootInterface} -p ${builtins.toString cfg.qrcpPort} receive";
      qr = "${lib.getExe pkgs.qrencode} -t ANSI256UTF8";
    };

    myHomeApps.openPorts = [ cfg.qrcpPort ];
  };
}
