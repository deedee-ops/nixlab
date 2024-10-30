{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.redlib;
in
{
  options.mySystemApps.redlib = {
    enable = lib.mkEnableOption "redlib container";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing redlib envs.";
      default = "system/apps/redlib/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.redlib = svc.mkContainer {
      cfg = {
        image = "quay.io/redlib/redlib:latest@sha256:26c521ec7646148f3f05d3817ce6525a5a8dba41644c802ad4f31b79423d59da";
        environment = {
          REDLIB_BANNER = "";
          REDLIB_DEFAULT_AUTOPLAY_VIDEOS = "off";
          REDLIB_DEFAULT_BLUR_NSFW = "on";
          REDLIB_DEFAULT_BLUR_SPOILER = "on";
          REDLIB_DEFAULT_COMMENT_SORT = "confidence";
          REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION = "off";
          REDLIB_DEFAULT_FILTERS = "";
          REDLIB_DEFAULT_FIXED_NAVBAR = "on";
          REDLIB_DEFAULT_FRONT_PAGE = "default";
          REDLIB_DEFAULT_HIDE_AWARDS = "on";
          REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "off";
          REDLIB_DEFAULT_HIDE_SCORE = "off";
          REDLIB_DEFAULT_HIDE_SIDEBAR_AND_SUMMARY = "off";
          REDLIB_DEFAULT_LAYOUT = "compact";
          REDLIB_DEFAULT_POST_SORT = "hot";
          REDLIB_DEFAULT_SHOW_NSFW = "on";
          REDLIB_DEFAULT_THEME = "dark";
          REDLIB_DEFAULT_USE_HLS = "on";
          REDLIB_DEFAULT_WIDE = "on";
          REDLIB_PUSHSHIFT_FRONTEND = "undelete.pullpush.io";
          REDLIB_ROBOTS_DISABLE_INDEXING = "on";
          REDLIB_SFW_ONLY = "off";
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
      };
      opts = {
        # proxying to reddit
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.redlib = svc.mkNginxVHost {
        host = "redlib";
        proxyPass = "http://redlib.docker:8080";
        useAuthelia = false;
      };
    };
  };
}
