{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.zigbee2mqtt;
in
{
  options.mySystemApps.zigbee2mqtt = {
    enable = lib.mkEnableOption "zigbee2mqtt container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/zigbee2mqtt";
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing zigbee2mqtt envs.";
      default = "system/apps/zigbee2mqtt/envfile";
    };
    serials = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      description = ''
        List of zigbee coordinator serial devices.
        Because one zigbee2mqtt can support only one coordinator,
        this would effectively spawn multiple zigbee2mqtt instances.
        The key will be URL and MQTT suffix. The value will be passed,
        as `serial` configuration option.
      '';
      example = {
        coordinator1 = {
          port = "/dev/ttyUSB0";
          disable_led = false;
          baudrate = 115200;
        };
        coordinator2 = {
          port = "tcp://192.168.1.1:6638";
          baudrate = 115200;
          adapter = "ezsp";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for zigbee2mqtt are disabled!") ];

    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers = builtins.listToAttrs (
      builtins.map (
        alias:
        let
          value = builtins.getAttr alias cfg.serials;
        in
        {
          name = "zigbee2mqtt-${alias}";
          value = svc.mkContainer {
            cfg = {
              image = "ghcr.io/koenkk/zigbee2mqtt:1.42.0@sha256:2dc89a4b6c798566d7f496ca3fcd795093be97555e9de8b9a3b5beaba49ecfb7";
              user = "65000:65000";
              environment = {
                ZIGBEE2MQTT_CONFIG_MQTT_USER = "mq";
                ZIGBEE2MQTT_DATA = "/config";
              };
              environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
              volumes = [
                "${cfg.dataDir}/${alias}/config:/config"
                "/run/udev:/run/udev:ro"
              ];
              extraOptions = [
                "--group-add=27" # dialout group in nixos, doesn't map 1:1 with container
              ] ++ lib.optionals (lib.strings.hasPrefix "/dev" value.port) [ "--device=${value.port}" ];
            };
          };
        }
      ) (builtins.attrNames cfg.serials)
    );

    services = {
      nginx.virtualHosts = builtins.listToAttrs (
        builtins.map (alias: {
          name = "zigbee2mqtt-${alias}";
          value = svc.mkNginxVHost {
            host = "zigbee2mqtt-${alias}";
            proxyPass = "http://zigbee2mqtt-${alias}.docker:8080";
          };
        }) (builtins.attrNames cfg.serials)
      );

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "zigbee2mqtt";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services = builtins.listToAttrs (
      builtins.map (
        alias:
        let
          serial = builtins.getAttr alias cfg.serials;
          configuration = pkgs.writeText "configuration.yaml" (
            builtins.toJSON (
              lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./configuration.json)) {
                inherit serial;
                mqtt.base_topic = "zigbee2mqtt_${alias}";
                frontend.url = "https://zigbee2mqtt-${alias}.${config.mySystem.rootDomain}";
              }
            )
          );
        in
        {
          name = "docker-zigbee2mqtt-${alias}";
          value = {
            preStart = lib.mkAfter ''
              mkdir -p "${cfg.dataDir}/${alias}/config"
              cp ${configuration} "${cfg.dataDir}/${alias}/config/configuration.yaml"
              chown 65000:65000 "${cfg.dataDir}/${alias}" "${cfg.dataDir}/${alias}/config" "${cfg.dataDir}/${alias}/config/configuration.yaml"
              chmod 640 "${cfg.dataDir}/${alias}/config/configuration.yaml"
            '';
          };
        }
      ) (builtins.attrNames cfg.serials)
    );

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Home = builtins.listToAttrs (
        builtins.map (alias: {
          name = "zigbee2mqtt-${alias}";
          value = svc.mkHomepage "zigbee2mqtt-${alias}" // {
            icon = "zigbee2mqtt.svg";
            description = "Zigbee compatibility layer";
          };
        }) (builtins.attrNames cfg.serials)
      );
    };
  };
}
