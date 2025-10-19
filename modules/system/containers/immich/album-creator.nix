{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.immich;
in
{
  config = lib.mkIf (cfg.enable && cfg.photosPath != null) {
    systemd =
      let
        image = "ghcr.io/salvoxia/immich-folder-album-creator:0.22.0@sha256:4435f5339a7cf52e4e7eeeb5ac2919f1c08da2eeafd5fc2682db4d0779cad470";
      in
      {
        services.docker-immich-album-creator = {
          description = "Run immich album creator";
          path = [ pkgs.docker ];
          serviceConfig.Type = "simple";
          script = ''
            exec docker  \
              run \
              --rm \
              --name=immich-album-creator \
              --log-driver=journald \
              -e ALBUM_LEVELS=1 \
              -e API_KEY=$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/AJGON_API_KEY".path}) \
              -e API_URL=http://immich-server:2283/api/ \
              -e MODE=CREATE \
              -e ROOT_PATH=/external \
              -e SYNC_MODE=1 \
              -e UNATTENDED=1 \
              -e TZ=${config.mySystem.time.timeZone} \
              --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 \
              -v ${cfg.photosPath}:/external:ro \
              --read-only \
              '--cap-drop=all' \
              '--security-opt=no-new-privileges' \
              '--add-host=host.docker.internal:172.30.0.1' \
              '--network=private' \
              ${image} /script/immich_auto_album.sh
          '';
        };

        timers.docker-immich-album-creator = {
          description = "Immich album creator timer.";
          wantedBy = [ "timers.target" ];
          partOf = [ "docker-recyclarr.service" ];
          timerConfig.OnCalendar = "daily";
          timerConfig.Persistent = "true";
        };
      };
  };
}
