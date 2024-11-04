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
    bridgeMainInterface = lib.mkOption {
      type = lib.types.bool;
      description = "If enabled, the main interface will me managed via bridge (useful for configurations with VMs).";
      default = false;
    };
    customNetworking = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      description = "Custom systemd.network config. If not set, DHCP4 on default interface will be configured.";
      default = null;
    };

    rootInterface = lib.mkOption {
      type = lib.types.str;
      description = ''
        Interface which will actually receive main IP, basing from configuration (may be mainInterface or bridge for example).
        Used internally for modules.
      '';
      internal = true;
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = cfg.hostname;
      dhcpcd.enable = false;
      enableIPv6 = false;
      firewall.enable = cfg.firewallEnable;
      nftables.enable = cfg.firewallEnable;
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

    mySystem.networking.rootInterface = if cfg.bridgeMainInterface then "br0" else cfg.mainInterface;

    systemd.network =
      if cfg.customNetworking == null then
        if cfg.bridgeMainInterface then
          {
            enable = true;
            links = {
              "0000-bridge-inherit-mac" = {
                matchConfig.Type = "bridge";
                linkConfig.MACAddressPolicy = "none";
              };
            };
            netdevs = {
              "0001-uplink" = {
                netdevConfig = {
                  Kind = "bridge";
                  Name = "br0";
                  MACAddress = "none";
                };
                bridgeConfig = {
                  # VLANFiltering = true;
                  STP = false;
                };
              };
            };

            networks = {
              "1002-add-main-to-br0" = {
                matchConfig.Name = "${config.mySystem.networking.mainInterface}";
                bridge = [ "br0" ];
              };
              "1003-br0-up" = {
                matchConfig.Name = "br0";
                networkConfig = {
                  DHCP = "ipv4";
                  LinkLocalAddressing = "ipv4"; # disable ipv6
                };
                linkConfig.RequiredForOnline = "routable";
              };
            };
          }
        else
          {
            enable = true;
            networks."50-${cfg.mainInterface}" = {
              matchConfig.Name = cfg.mainInterface;
              networkConfig = {
                DHCP = "ipv4";
                LinkLocalAddressing = "ipv4"; # disable ipv6
              };
              linkConfig.RequiredForOnline = "routable";
            };
          }
      else
        lib.recursiveUpdate cfg.customNetworking { enable = true; };
  };
}
