{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.beszel;
in
{
  options.mySystemApps.beszel = {
    enable = lib.mkEnableOption "beszel container";
    mode = lib.mkOption {
      type = lib.types.enum [
        "hub"
        "agent"
        "both"
      ];
      description = "Mode in which beszel will run. When 'both' and agent will connect to hub via socket on the same machine.";
      example = "agent";
    };
    gpuMode = lib.mkOption {
      type = lib.types.enum [
        "none"
        "nvidia"
      ];
      description = "Support for given GPU in agent (at a cost of much larger container image).";
      default = "none";
    };
    monitoredFilesystems = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Attrset of filesystems to be monitored, in format of <alias> = <mountpoint on given fs>";
      default = { };
      example = {
        root = "/";
        tank = "/tank";
      };
    };
    rootFs = lib.mkOption {
      type = lib.types.str;
      description = "Main filesystem used for monitoring disk stats.";
      default = "/";
    };
    agentKeySopsSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Sops secret name containing agent key.";
      default = "system/apps/beszel/agent-key";
    };
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/beszel";
    };
  };

  config =
    let
      isAgent = cfg.mode == "agent" || cfg.mode == "both";
      isHub = cfg.mode == "hub" || cfg.mode == "both";
    in
    lib.mkIf cfg.enable {
      warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for beszel are disabled!") ];

      sops.secrets = lib.mkIf isAgent {
        "${cfg.agentKeySopsSecret}" = {
          restartUnits = [ "docker-beszel-agent.service" ];
        };
      };

      mySystemApps = {
        authelia.oidcClients = lib.optionals isHub [
          {
            client_id = "beszel";
            client_name = "Beszel";
            client_secret = "$pbkdf2-sha512$310000$aIH5bbBT/dODqbPjsw3Chg$OuJn9eIcMr3Z7lXI5UwFQ/6..EULa0yfD4n.T9ACTeQCQyhUzGL.EaMM3AEMSyXmhZg83MXszhHIK50hY6rG8g"; # unencrypted version in SOPS
            consent_mode = "implicit";
            public = false;
            authorization_policy = "two_factor";
            require_pkce = false;
            redirect_uris = [
              "https://beszel.${config.mySystem.rootDomain}/api/oauth2-redirect"
            ];
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
        docker = lib.mkIf isAgent {
          startDockerSockProxy = true;
        };
      };

      virtualisation.oci-containers.containers.beszel-hub = lib.mkIf isHub (
        svc.mkContainer {
          cfg = {
            image = "ghcr.io/henrygd/beszel/beszel:0.13.1@sha256:6901ce3c18cae5178bb6ee2526dc9defbb6dc1dabdfc94b3fdd3551d1cb55de3";
            environment = {
              SHARE_ALL_SYSTEMS = "true";
            };
            volumes = [
              "${cfg.dataDir}/server:/beszel_data"
            ]
            ++ lib.optionals (cfg.mode == "both") [ "/var/cache/beszel:/beszel_socket" ];

            extraOptions = [
              "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
            ];
          };
          opts = {
            # connecting to agents
            allowPublic = true;
          };
        }
      );
      virtualisation.oci-containers.containers.beszel-agent = lib.mkIf isAgent (
        svc.mkContainer {
          cfg = {
            dependsOn = [ "socket-proxy" ];
            image = "ghcr.io/henrygd/beszel/beszel-agent:0.13.1@sha256:d690417aae5df1ce67121708af5eb7dde24cdd00773ca9be5acaaf0e4577934b";
            environment = {
              DOCKER_HOST = "tcp://127.0.0.1:2375";
              FILESYSTEM = cfg.rootFs;
              KEY_FILE = "/secrets/key";
              LISTEN = if cfg.mode == "both" then "/beszel_socket/beszel.sock" else "45876";
            };
            volumes = [
              "${config.sops.secrets."${cfg.agentKeySopsSecret}".path}:/secrets/key:ro"
            ]
            ++ (builtins.map (
              name: "${builtins.getAttr name cfg.monitoredFilesystems}/.beszel:/extra-filesystems/${name}:ro"
            ) (builtins.attrNames cfg.monitoredFilesystems))
            ++ lib.optionals (cfg.mode == "both") [ "/var/cache/beszel:/beszel_socket" ];
          };
          opts = {
            useHostNetwork = true;
            enableGPU = cfg.gpuMode == "nvidia";
          };
        }
        // (lib.optionalAttrs (cfg.gpuMode == "nvidia") {
          image = "ghcr.io/arunoruto/beszel-agent:0.13.1@sha256:b0abd165e8e0fa2281f7ae294b09a6c2124e28325198ad152101ac6bea2dcf28";
        })
      );

      networking.firewall.allowedTCPPorts = lib.optionals (cfg.mode == "agent") [ 45876 ];

      services = lib.mkIf isHub {
        nginx.virtualHosts.beszel = svc.mkNginxVHost {
          host = "beszel";
          proxyPass = "http://beszel-hub.docker:8090";
        };
        restic.backups = lib.mkIf cfg.backup (
          svc.mkRestic {
            name = "beszel";
            paths = [ cfg.dataDir ];
          }
        );
      };

      environment.persistence."${config.mySystem.impermanence.persistPath}" = lib.mkIf (
        config.mySystem.impermanence.enable && isHub
      ) { directories = [ cfg.dataDir ]; };

      mySystemApps.homepage = lib.mkIf isHub {
        services.Apps.Beszel = svc.mkHomepage "beszel" // {
          container = "beszel-hub";
          description = "Machines monitoring";
        };
      };
    };
}
