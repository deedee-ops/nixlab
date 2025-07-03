{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.letsencrypt;

  syncCerts = pkgs.writeShellScriptBin "sync-certs.sh" ''
    TARGET="$1"
    CERT_DIR="$2"

    if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
      echo "Missing certificate"
      exit 1
    fi

    if [ ! -f "$CERT_DIR/key.pem" ]; then
      echo "Missing certificate key"
      exit 1
    fi

    if [[ "$TARGET" == "unifi" ]]; then
      scp -o "StrictHostKeyChecking=no" -i ${
        config.sops.secrets."system/apps/letsencrypt/unifi_ssh_key".path
      } "$CERT_DIR/fullchain.pem" "root@${config.myInfra.machines.unifi.ip}:/data/unifi-core/config/d5536a1d-cc4c-4516-bdc0-5fc934a5e82e.crt"
      scp -o "StrictHostKeyChecking=no" -i ${
        config.sops.secrets."system/apps/letsencrypt/unifi_ssh_key".path
      } "$CERT_DIR/key.pem" "root@${config.myInfra.machines.unifi.ip}:/data/unifi-core/config/d5536a1d-cc4c-4516-bdc0-5fc934a5e82e.key"
      ssh -o "StrictHostKeyChecking=no" -i ${
        config.sops.secrets."system/apps/letsencrypt/unifi_ssh_key".path
      } -t "root@${config.myInfra.machines.unifi.ip}" "service nginx reload"
    else
      echo "Unknown TARGET: $TARGET"
      exit 1
    fi
  '';
in
{
  config = lib.mkIf (cfg.enable && (cfg.syncCerts.unifi != null)) {
    systemd = {
      services.sync-certs = {
        description = "Sync certificates";
        path = [ pkgs.curl ];
        serviceConfig.Type = "simple";
        script = lib.optionalString (cfg.syncCerts.unifi != null) ''
          ${lib.getExe syncCerts} unifi ${config.security.acme.certs."${cfg.syncCerts.unifi}".directory}
        '';
      };

      timers.sync-certs = {
        description = "Sync certificates";
        wantedBy = [ "timers.target" ];
        partOf = [ "sync-certs.service" ];
        timerConfig.OnCalendar = "daily";
        timerConfig.Persistent = "true";
      };
    };
  };
}
