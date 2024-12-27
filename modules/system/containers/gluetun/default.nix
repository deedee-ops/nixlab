{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.gluetun;
  forwardedPort = builtins.toString cfg.forwardedPort;
  extraPortsMap = builtins.map (
    port: "${builtins.toString port}:${builtins.toString port}"
  ) cfg.extraPorts;
  secretEnvs = [
    "WIREGUARD_ADDRESSES"
    "WIREGUARD_PRESHARED_KEY"
    "WIREGUARD_PRIVATE_KEY"
  ];
in
{
  options.mySystemApps.gluetun = {
    enable = lib.mkEnableOption "gluetun container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    forwardedPort = lib.mkOption {
      type = lib.types.port;
      description = "VPN forwarded port.";
    };
    extraPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      description = ''
        Extra ports exposed from the gluetun container,
        which can be used to expose ports from other containers connected to gluetun network.
      '';
      default = [ ];
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/gluetun/env";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "gluetun";
    };

    boot.kernelModules = [ "wireguard" ];

    virtualisation.oci-containers.containers.gluetun = svc.mkContainer {
      cfg = {
        image = "ghcr.io/qdm12/gluetun:latest@sha256:62e76d60e4220950558215647049c2b9ef0fc64272b80f9012562555b140bf84";
        environment =
          {
            DOT = "off";
            FIREWALL_VPN_INPUT_PORTS = forwardedPort;
            SERVER_COUNTRIES = "Netherlands";
            UPDATER_PERIOD = "24h";
            VPN_INTERFACE = "wg0";
            VPN_SERVICE_PROVIDER = "airvpn";
            VPN_TYPE = "wireguard";
          }
          // svc.mkContainerSecretsEnv {
            inherit secretEnvs;
            suffix = "_SECRETFILE";
          };
        ports = [ "${forwardedPort}:${forwardedPort}" ] ++ extraPortsMap;
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
        extraOptions = [
          "--cap-add=CAP_NET_ADMIN"
          "--device=/dev/net/tun"
        ];
      };
      opts = {
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.forwardedPort ];
    networking.firewall.allowedUDPPorts = [ cfg.forwardedPort ];
  };
}
