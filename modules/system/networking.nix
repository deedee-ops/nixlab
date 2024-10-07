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
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = cfg.hostname;
      dhcpcd.enable = false;
      firewall.enable = cfg.firewallEnable;
      enableIPv6 = false;
      useDHCP = false;
      useHostResolvConf = false;
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
