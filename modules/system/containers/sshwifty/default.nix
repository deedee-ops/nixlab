{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.sshwifty;
  sshwiftyConfig = pkgs.writeText "sshwifty.conf.json" (
    builtins.toJSON (
      (builtins.fromJSON (builtins.readFile ./sshwifty.conf.json))
      // {
        Presets = builtins.map (preset: {
          Title = preset.title;
          Type = "SSH";
          Host = preset.host;
          Meta = {
            User = preset.user;
            "Private Key" = "file:///secrets/${preset.privateKeyName}";
            Authentication = "Private Key";
          };
        }) cfg.presets;
        OnlyAllowPresetRemotes = cfg.onlyAllowPresetRemotes;
      }
    )
  );
in
{
  options.mySystemApps.sshwifty = {
    enable = lib.mkEnableOption "sshwifty container";
    presets = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            title = lib.mkOption {
              type = lib.types.str;
              example = "SDF.org Unix Shell";
            };
            host = lib.mkOption {
              type = lib.types.str;
              example = "sdf.org:22";
            };
            user = lib.mkOption {
              type = lib.types.str;
              example = "pre-defined-username";
            };
            privateKeyName = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret value (excluding prefix) for private key.";
            };
          };
        }
      );
      description = "Connection presets list.";
      default = [ ];
    };
    onlyAllowPresetRemotes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow only connecting to hosts defined in presets.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all private keys will be appended.";
      default = "system/apps/sshwifty/keys";
    };
    secretKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of secret keys provided under sops prefix";
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      secretEnvs = cfg.secretKeys;

      containerName = "sshwifty";
    };

    virtualisation.oci-containers.containers.sshwifty = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/sshwifty:0.3.20-beta-release@sha256:2446e2aad31a0c06f6f6e33027ae52fefebc84b915ea87c59a36a8e19c269693";
        user = "65000:65000";
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            secretEnvs = cfg.secretKeys;
          }
          ++ [ "${sshwiftyConfig}:/etc/sshwifty.conf.json" ];
      };
      opts = {
        # connect to SSH machines
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.sshwifty = svc.mkNginxVHost {
        host = "ssh";
        proxyPass = "http://sshwifty.docker:8182";
      };
    };

    mySystemApps.homepage = {
      services.Apps.SSHwifty = svc.mkHomepage "sshwifty" // {
        href = "https://ssh.${config.mySystem.rootDomain}";
        description = "SSH client";
      };
    };
  };
}
