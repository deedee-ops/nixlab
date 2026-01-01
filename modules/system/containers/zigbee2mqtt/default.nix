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
    coordinators = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            envFileSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing given instance envs.";
            };
            config = lib.mkOption {
              type = lib.types.attrs;
              description = ''
                Configuration options, whill will be merged directly to instance
                configuration file.
              '';
            };
          };
        }
      );
      description = ''
        List of multiple zigbee coordinator configuration stanzas.
        Because one zigbee2mqtt can support only one coordinator,
        this would effectively spawn multiple zigbee2mqtt instances.
        The key will be URL and MQTT suffix. The value.config will be merged,
        with the default config. At least, you need to add `serial`
        stanza here.
      '';
      example = {
        coordinator1 = {
          envFileSopsSecret = "system/apps/zigbee2mqtt/coordinator1/envfile";
          config = {
            advanced = {
              transmit_power = 20;
            };
            serial = {
              port = "/dev/ttyUSB0";
              disable_led = false;
              baudrate = 115200;
            };
          };
        };
        coordinator2 = {
          envFileSopsSecret = "system/apps/zigbee2mqtt/coordinator1/envfile";
          config = {
            serial = {
              port = "tcp://192.168.1.1:6638";
              baudrate = 115200;
              adapter = "ezsp";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for zigbee2mqtt are disabled!") ];

    sops.secrets = builtins.listToAttrs (
      builtins.map (alias: {
        name = (builtins.getAttr alias cfg.coordinators).envFileSopsSecret;
        value = { };
      }) (builtins.attrNames cfg.coordinators)
    );

    mySystemApps.mosquitto.enable = true;

    virtualisation.oci-containers.containers = builtins.listToAttrs (
      builtins.map (
        alias:
        let
          coordinator = builtins.getAttr alias cfg.coordinators;
        in
        {
          name = "zigbee2mqtt-${alias}";
          value = svc.mkContainer {
            cfg = {
              image = "ghcr.io/koenkk/zigbee2mqtt:2.7.2@sha256:60a295b40f4e7fb7ab4d995932369e50f2529837272fa4979e986ec1ffdb7fce";
              user = "65000:65000";
              environment = {
                ZIGBEE2MQTT_CONFIG_MQTT_USER = "mq";
                ZIGBEE2MQTT_DATA = "/config";
              };
              environmentFiles = [ config.sops.secrets."${coordinator.envFileSopsSecret}".path ];
              volumes = [
                "${cfg.dataDir}/${alias}/config:/config"
                "/run/udev:/run/udev:ro"
              ];
              extraOptions = [
                "--group-add=27" # dialout group in nixos, doesn't map 1:1 with container
                "--cap-add=CAP_NET_BIND_SERVICE"
              ]
              ++ lib.optionals (lib.strings.hasPrefix "/dev" coordinator.config.serial.port) [
                "--device=${coordinator.config.serial.port}"
              ];
            };
            opts = {
              # access remote coordinator
              allowPublic = true;
            };
          };
        }
      ) (builtins.attrNames cfg.coordinators)
    );

    services = {
      nginx.virtualHosts = builtins.listToAttrs (
        builtins.map (alias: {
          name = "zigbee2mqtt-${alias}";
          value = svc.mkNginxVHost {
            host = "zigbee2mqtt-${alias}";
            proxyPass = "http://zigbee2mqtt-${alias}.docker:8080";
            customCSP = ''
              default-src 'self' 'unsafe-inline' data: blob: wss:;
              img-src 'self' data: https://www.zigbee2mqtt.io;
              object-src 'none';
              style-src 'self' 'unsafe-inline' data: blob: *.${config.mySystem.rootDomain};
            '';
          };
        }) (builtins.attrNames cfg.coordinators)
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
          configuration = pkgs.writeText "configuration.yaml" (
            builtins.toJSON (
              lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./configuration.json)) (
                lib.recursiveUpdate {
                  mqtt.base_topic = "zigbee2mqtt_${alias}";
                  # frontend.url = "https://zigbee2mqtt-${alias}.${config.mySystem.rootDomain}";
                } (builtins.getAttr alias cfg.coordinators).config
              )
            )
          );
        in
        {
          name = "docker-zigbee2mqtt-${alias}";
          value = {
            preStart = lib.mkAfter ''
              mkdir -p "${cfg.dataDir}/${alias}/config"
              [ ! -f "${cfg.dataDir}/${alias}/config/configuration.yaml" ] && cp ${configuration} "${cfg.dataDir}/${alias}/config/configuration.yaml"
              chown 65000:65000 "${cfg.dataDir}/${alias}" "${cfg.dataDir}/${alias}/config" "${cfg.dataDir}/${alias}/config/configuration.yaml"
              chmod 640 "${cfg.dataDir}/${alias}/config/configuration.yaml"
            '';
          };
        }
      ) (builtins.attrNames cfg.coordinators)
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
        }) (builtins.attrNames cfg.coordinators)
      );
    };
  };
}
