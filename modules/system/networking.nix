{ config, lib, ... }:
let
  cfg = config.mySystem.networking;
in
{
  options.mySystem.networking = {
    enable = lib.mkEnableOption "system networking";
    firewallEnable = lib.mkEnableOption "firewall";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Machine hostname.";
    };
    mainInterface = lib.mkOption {
      type = lib.types.str;
      description = "Main interface which will receive default routing";
    };
    fallbackDNS = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = [
        "9.9.9.9"
        "149.112.112.10"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = cfg.hostname;
      dhcpcd.enable = false;
      enableIPv6 = false;
      firewall.enable = cfg.firewallEnable;
      resolvconf.enable = false;
      useDHCP = false;
      useHostResolvConf = false;
    };

    services = {
      resolved = {
        enable = lib.mkDefault true;
        fallbackDns = cfg.fallbackDNS;
      };
    };

    systemd.network = {
      enable = true;
      networks."50-${cfg.mainInterface}" = {
        matchConfig.Name = cfg.mainInterface;
        networkConfig = {
          DHCP = "ipv4";
          LinkLocalAddressing = "ipv4"; # disable ipv6
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
