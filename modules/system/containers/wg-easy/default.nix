{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.wg-easy;
in
{
  options.mySystemApps.wg-easy = {
    enable = lib.mkEnableOption "wg-easy container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/wg-easy";
    };
    allowedCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of allowed CIDRs to be exposed from internal network via wireguard.";
      default = [ ];
      example = [ "192.168.0.0/16" ];
    };
    advertisedDNSServer = lib.mkOption {
      type = lib.types.str;
      description = "DNS server which will be advertised to wireguard clients.";
      example = "1.1.1.1";
    };
    externalHost = lib.mkOption {
      type = lib.types.str;
      description = "IP/host available from outside world, which can be used to connect to the Wireguard.";
      example = "mywg.example.com";
    };
    wireguardPort = lib.mkOption {
      type = lib.types.port;
      description = "Exposed wireguard UDP port.";
      default = 51820;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for wg-easy are disabled!") ];

    boot.kernelModules = [ "iptable_nat" ];

    virtualisation.oci-containers.containers.wg-easy = svc.mkContainer {
      cfg = {
        image = "ghcr.io/wg-easy/wg-easy:14@sha256:66352ccb4b5095992550aa567df5118a5152b6ed31be34b0a8e118a3c3a35bf5";
        environment = {
          LANG = "en";
          PORT = "51821";
          UI_CHART_TYPE = "2";
          UI_TRAFFIC_STATS = "true";
          WG_ALLOWED_IPS = builtins.concatStringsSep ", " cfg.allowedCIDRs;
          WG_DEFAULT_ADDRESS = "10.250.1.x";
          WG_DEFAULT_DNS = cfg.advertisedDNSServer;
          WG_HOST = cfg.externalHost;
          WG_PORT = builtins.toString cfg.wireguardPort;
        };
        ports = [ "${builtins.toString cfg.wireguardPort}:${builtins.toString cfg.wireguardPort}/udp" ];
        volumes = [ "${cfg.dataDir}:/etc/wireguard" ];
        extraOptions = [
          "--cap-add=CAP_NET_ADMIN"
          "--cap-add=CAP_NET_RAW"
          "--cap-add=CAP_SYS_MODULE"
          "--sysctl"
          "net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl"
          "net.ipv4.ip_forward=1"
        ];
      };
      opts = {
        # to allow connections from outside
        allowPublic = true;
        disableReadOnly = true;
      };
    };

    services = {
      nginx.virtualHosts.wg-easy = svc.mkNginxVHost {
        host = "wg";
        proxyPass = "http://wg-easy.docker:51821";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "wg-easy";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.wg-easy = svc.mkHomepage "wg-easy" // {
        href = "https://wg.${config.mySystem.rootDomain}";
        icon = "wireguard.svg";
        description = "Wireguard clients manager";
        widget = {
          type = "wgeasy";
          url = "http://wg-easy:51821";
          threshold = 1;
          password = "";
          fields = [
            "connected"
            "enabled"
            "total"
          ];
        };
      };
    };
  };
}