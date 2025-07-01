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
    wireguardNetworkCIDR = lib.mkOption {
      type = lib.types.str;
      description = "CIDR for wireguard network, must end with .0/24";
      example = "192.168.100.0/24";
    };
    wireguardPort = lib.mkOption {
      type = lib.types.port;
      description = "Exposed wireguard UDP port.";
      default = 51820;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for wg-easy are disabled!") ];

    assertions = [
      {
        assertion = lib.strings.hasSuffix ".0/24" cfg.wireguardNetworkCIDR;
        message = "WG network CIDR, must end with .0/24";
      }
    ];

    boot.kernelModules = [ "iptable_nat" ];

    virtualisation.oci-containers.containers.wg-easy = svc.mkContainer {
      cfg = {
        image = "ghcr.io/wg-easy/wg-easy:15@sha256:bb8152762c36f824eb42bb2f3c5ab8ad952818fbef677d584bc69ec513b251b0";
        environment = {
          LANG = "en";
          PORT = "51821";
          UI_CHART_TYPE = "2";
          UI_TRAFFIC_STATS = "true";
          WG_ALLOWED_IPS = builtins.concatStringsSep ", " cfg.allowedCIDRs;
          WG_DEFAULT_ADDRESS = builtins.replaceStrings [ ".0/24" ] [ ".x" ] cfg.wireguardNetworkCIDR;
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
        readOnlyRootFilesystem = false;
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

    networking.firewall.allowedUDPPorts = [ cfg.wireguardPort ];

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
