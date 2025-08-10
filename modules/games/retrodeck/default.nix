{
  config,
  osConfig,
  lib,
  ...
}:
let
  cfg = config.myGames.retrodeck;
in
{
  options.myGames.retrodeck = {
    enable = lib.mkEnableOption "World of Warcraft";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = osConfig.mySystem.flatpakEnable;
        message = "Flatpaks need to be enabled on mySystem level to install retrodeck.";
      }
    ];

    services.flatpak.packages = [ "net.retrodeck.retrodeck" ];
  };
}
