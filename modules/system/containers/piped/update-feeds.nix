{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.piped;
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.sopsSecretPrefix}/PIPED_DB_PASSWORD" = { };

    systemd = {
      services.docker-piped-update-feeds = {
        description = "Update piped feeds";
        path = [
          pkgs.curl
          pkgs.dnsutils
          pkgs.jq
          pkgs.postgresql
        ];
        serviceConfig.Type = "simple";
        script =
          let
            updateFeeds = lib.getExe (
              pkgs.writeShellScriptBin "update-feeds.sh" (builtins.readFile ./update-feeds.sh)
            );
          in
          ''
            BACKEND_URL="http://$(${lib.getExe' pkgs.dnsutils "dig"} +short -p 5533 piped-api.docker @127.0.0.1):8080"

            ${updateFeeds} videos "$BACKEND_URL" ${
              config.sops.secrets."${cfg.sopsSecretPrefix}/PIPED_DB_PASSWORD".path
            }
            ${updateFeeds} streams "$BACKEND_URL" ${
              config.sops.secrets."${cfg.sopsSecretPrefix}/PIPED_DB_PASSWORD".path
            }
          '';
      };

      timers.docker-piped-update-feeds = {
        description = "Update pipied feeds timer.";
        wantedBy = [ "timers.target" ];
        partOf = [ "docker-piped-update-feeds.service" ];
        timerConfig.OnCalendar = "*:0/15";
        timerConfig.Persistent = "true";
      };
    };
  };
}
