{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.tftpd;
in
{
  options.mySystemApps.tftpd = {
    enable = lib.mkEnableOption "tftpd container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    useHostNetwork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Sometimes docker adds too much overhead, and network stack gets crazy. Using host networking may help.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing files.";
      default = "/var/lib/tftpd";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.tftpd = svc.mkContainer {
      cfg = {
        image = "registry.gitlab.com/kalaksi-containers/tftpd:1.6@sha256:41f614ba418aaba5efe1a6a3a166f66c4414f9dfcbc0b579f9dce91d667f5e0d";
        environment = {
          TFTPD_BIND_ADDRESS = "0.0.0.0:" + (lib.optionalString (!cfg.useHostNetwork) "10") + "69";
        };
        ports = lib.optionals (!cfg.useHostNetwork) [ "69:1069/udp" ];
        volumes = [
          "${cfg.dataDir}:/tftpboot"
        ];
        extraOptions = [
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_SYS_CHROOT"
        ] ++ lib.optionals cfg.useHostNetwork [ "--cap-add=CAP_NET_BIND_SERVICE" ];
      };
      opts = {
        inherit (cfg) useHostNetwork;
        # expose port
        allowPublic = true;
      };
    };

    services = {
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "tftpd";
          paths = [ cfg.dataDir ];
        }
      );
    };

    networking.firewall.allowedUDPPorts = [ 69 ];

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              user = config.users.users.abc.name;
              group = config.users.groups.abc.name;
              directory = cfg.dataDir;
              mode = "755";
            }
          ];
        };
  };
}
