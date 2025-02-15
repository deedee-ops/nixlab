{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.recyclarr;
in
{
  options.mySystemApps.recyclarr = {
    enable = lib.mkEnableOption "recyclarr container";
    radarrApiKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "SOPS secret containing radarr api key";
      default = "system/apps/radarr/env/RADARR__AUTH__APIKEY";
    };
    sonarrApiKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "SOPS secret containing sonarr api key";
      default = "system/apps/sonarr/env/SONARR__AUTH__APIKEY";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.radarrApiKeySopsSecret}" = { };
    sops.secrets."${cfg.sonarrApiKeySopsSecret}" = { };

    systemd =
      let
        image = "ghcr.io/recyclarr/recyclarr:7.4.1@sha256:759540877f95453eca8a26c1a93593e783a7a824c324fbd57523deffb67f48e1";
      in
      {
        services.docker-recyclarr = {
          description = "Run recyclarr";
          path = [ pkgs.docker ];
          serviceConfig.Type = "simple";
          script = ''
            set -e

            exec docker  \
              run \
              --rm \
              --name=recyclarr \
              --log-driver=journald \
              -e RADARR_API_KEY=$(cat ${config.sops.secrets."${cfg.radarrApiKeySopsSecret}".path}) \
              -e SONARR_API_KEY=$(cat ${config.sops.secrets."${cfg.sonarrApiKeySopsSecret}".path}) \
              -e TZ=${config.mySystem.time.timeZone} \
              -v ${./recyclarr.yml}:/config/recyclarr.yml:ro \
              --read-only \
              '--cap-drop=all' \
              '--security-opt=no-new-privileges' \
              '--add-host=host.docker.internal:172.30.0.1' \
              '--network=private' \
              '--network=public' \
              ${image} sync
          '';
        };

        timers.docker-recyclarr = {
          description = "Recyclarr timer.";
          wantedBy = [ "timers.target" ];
          partOf = [ "docker-recyclarr.service" ];
          timerConfig.OnCalendar = "0/08:00:00";
          timerConfig.Persistent = "true";
        };
      };
  };
}
