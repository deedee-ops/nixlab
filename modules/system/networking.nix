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
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Main interface which will receive default routing";
          };
          bridge = lib.mkOption {
            type = lib.types.bool;
            description = "If enabled, the main interface will me managed via bridge (useful for configurations with VMs).";
            default = false;
          };
          DNS = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            description = "If enabled, the DNS servers of main interface will be overriden manually, instead of using the DHCP provided ones.";
            default = null;
          };
        };
      };
    };
    fallbackDNS = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = [
        "9.9.9.9"
        "149.112.112.10"
      ];
    };
    customNetworking = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      description = "Custom systemd.network config. If not set, DHCP4 on default interface will be configured.";
      default = null;
    };
    extraHosts = lib.mkOption {
      type = lib.types.lines;
      description = "Extra entries in /etc/hosts";
      default = "";
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
      inherit (cfg) extraHosts;

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

    mySystem.networking.rootInterface =
      if cfg.mainInterface.bridge then "br0" else cfg.mainInterface.name;

    systemd.network =
      if cfg.customNetworking == null then
        if cfg.mainInterface.bridge then
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
                matchConfig.Name = "${cfg.mainInterface.name}";
                bridge = [ "br0" ];
              };
              "1003-br0-up" = {
                matchConfig.Name = "br0";
                networkConfig = {
                  inherit (cfg.mainInterface) DNS;

                  DHCP = "ipv4";
                  LinkLocalAddressing = "ipv4"; # disable ipv6
                };
                dhcpV4Config = lib.mkIf (cfg.mainInterface.DNS != null) { UseDNS = false; };
                linkConfig.RequiredForOnline = "routable";
              };
            };
          }
        else
          {
            enable = true;
            networks."50-${cfg.mainInterface.name}" = {
              matchConfig.Name = cfg.mainInterface.name;
              networkConfig = {
                inherit (cfg.mainInterface) DNS;

                DHCP = "ipv4";
                LinkLocalAddressing = "ipv4"; # disable ipv6
              };
              dhcpV4Config = lib.mkIf (cfg.mainInterface.DNS != null) { UseDNS = false; };
              linkConfig.RequiredForOnline = "routable";
            };
          }
      else
        lib.recursiveUpdate cfg.customNetworking { enable = true; };
  };
}
