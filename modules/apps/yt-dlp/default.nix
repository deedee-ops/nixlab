{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.yt-dlp;
in
{
  options.myHomeApps.yt-dlp = {
    enable = lib.mkEnableOption "yt-dlp";
  };

  config = lib.mkIf cfg.enable {
    programs.yt-dlp = {
      enable = true;

      settings = {
        sponsorblock-remove = "sponsor,selfpromo";
        restrict-filenames = true;
      };
    };
  };
}
