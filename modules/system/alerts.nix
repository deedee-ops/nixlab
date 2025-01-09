{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.alerts;
in
{
  options = {
    systemd.services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          config.onFailure = lib.optionals cfg.pushover.enable [ "notify-pushover@%n.service" ];
        }
      );
    };

    mySystem.alerts = {
      pushover = {
        enable = lib.mkEnableOption "pushover alerts";
        envFileSopsSecret = lib.mkOption {
          type = lib.types.str;
          description = "Sops secret name containing pushover credentials envs.";
          default = "alerts/pushover/env";
        };
      };
    };
  };

  config = lib.mkIf cfg.pushover.enable {
    warnings = [
      (lib.mkIf (!cfg.pushover.enable) "WARNING: Pushover alerts are disabled!")
    ];

    sops.secrets = {
      "${cfg.pushover.envFileSopsSecret}" = { };
    };

    systemd.services = {
      "notify-pushover@" = lib.mkIf cfg.pushover.enable {
        enable = true;
        onFailure = lib.mkForce [ ]; # cant refer to itself on failure
        description = "Notify on failed unit %i";
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = config.sops.secrets."${cfg.pushover.envFileSopsSecret}".path;
        };

        scriptArgs = "%i %H";
        script = ''
          # hack to mute notifier during deployments
          if pgrep -f deploy-rs; then
            exit 0
          fi

          ${pkgs.curl}/bin/curl --fail -s -o /dev/null \
            --form-string "token=$PUSHOVER_API_KEY" \
            --form-string "user=$PUSHOVER_USER_KEY" \
            --form-string "priority=1" \
            --form-string "html=1" \
            --form-string "timestamp=$(date +%s)" \
            --form-string "title=Unit failure: '$1' on $2" \
            --form-string "message=<b>$1</b> has failed on <b>$2</b><br><u>Journal tail:</u><br><br><i>$(journalctl -u $1 -n 10 -o cat)</i>" \
            https://api.pushover.net/1/messages.json 2>&1
        '';
      };
    };
  };
}
