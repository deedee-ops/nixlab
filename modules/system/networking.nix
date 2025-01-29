{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.networking;
in
{
  options.mySystem.networking = {
    enable = lib.mkEnableOption "system networking";
    firewallEnable = lib.mkEnableOption "firewall";
    wifiSupport = lib.mkEnableOption "WiFi support";
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
            description = "If enabled, the main interface will be managed via bridge (useful for configurations with VMs).";
            default = false;
          };
          bridgeMAC = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Force bridge MAC address instead of picking it up from main interface.";
            default = null;
          };
          DNS = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            description = "If enabled, the DNS servers of main interface will be overriden manually, instead of using the DHCP provided ones.";
            default = null;
          };
        };
      };
    };
    secondaryInterface = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Main interface which will receive default routing";
            };
            DNS = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              description = "If enabled, the DNS servers of main interface will be overriden manually, instead of using the DHCP provided ones.";
              default = null;
            };
          };
        }
      );
      default = null;
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
    assertions = [
      {
        assertion =
          (!cfg.mainInterface.bridge)
          || (!config.mySystemApps.incus.enable)
          || (cfg.mainInterface.bridgeMAC != null);
        message = "Incus tends to break bridge MAC address, when in auto mode - thus when enabled, mySystem.macInterface.bridgeMAC is required.";
      }
      {
        assertion = cfg.secondaryInterface == null || cfg.customNetworking == null;
        message = "secondaryInterface is ignored, when customNetworking is set";
      }
    ];

    networking = {
      inherit (cfg) extraHosts;

      hostName = cfg.hostname;
      dhcpcd.enable = false;
      enableIPv6 = false;
      firewall = {
        enable = cfg.firewallEnable;
        checkReversePath =
          if cfg.secondaryInterface == null && cfg.customNetworking == null then "strict" else "loose";
      };
      nftables.enable = cfg.firewallEnable;
      resolvconf.enable = false;
      useDHCP = false;
      useHostResolvConf = false;
      interfaces =
        {
          "${cfg.mainInterface.name}".wakeOnLan.enable = true;
        }
        // lib.optionalAttrs (cfg.secondaryInterface != null) {
          "${cfg.secondaryInterface.name}".wakeOnLan.enable = true;
        };

      networkmanager.enable = cfg.wifiSupport;
    };

    services = {
      resolved = {
        enable = lib.mkDefault true;
        fallbackDns = cfg.fallbackDNS;
      };
    };

    mySystem.networking.rootInterface =
      if cfg.mainInterface.bridge then "br0" else cfg.mainInterface.name;

    systemd = lib.mkIf (!cfg.wifiSupport) {
      network =
        if cfg.customNetworking == null then
          if cfg.mainInterface.bridge then
            {
              enable = true;
              links = {
                "0000-bridge-inherit-mac" =
                  {
                    matchConfig.Type = "bridge";
                  }
                  // (
                    if cfg.mainInterface.bridgeMAC == null then
                      { linkConfig.MACAddressPolicy = "none"; }
                    else
                      { linkConfig.MACAddress = cfg.mainInterface.bridgeMAC; }
                  );
              };
              netdevs = {
                "0001-uplink" = {
                  netdevConfig =
                    {
                      Kind = "bridge";
                      Name = "br0";
                    }
                    // lib.optionalAttrs (cfg.mainInterface.bridgeMAC == null) {
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
                  dhcpV4Config = {
                    UseDomains = true;
                  } // lib.optionalAttrs (cfg.mainInterface.DNS != null) { UseDNS = false; };
                  linkConfig.RequiredForOnline = "routable";
                };
              };
            }
          else
            {
              enable = true;
              networks =
                {
                  "50-${cfg.mainInterface.name}" = {
                    matchConfig.Name = cfg.mainInterface.name;
                    networkConfig = {
                      inherit (cfg.mainInterface) DNS;

                      DHCP = "ipv4";
                      LinkLocalAddressing = "ipv4"; # disable ipv6
                    };
                    dhcpV4Config = {
                      UseDomains = true;
                    } // lib.optionalAttrs (cfg.mainInterface.DNS != null) { UseDNS = false; };
                    linkConfig.RequiredForOnline = "routable";
                  };
                }
                // lib.optionalAttrs (cfg.secondaryInterface != null) {
                  "55-${cfg.secondaryInterface.name}" = {
                    matchConfig.Name = cfg.secondaryInterface.name;
                    networkConfig = {
                      inherit (cfg.secondaryInterface) DNS;

                      DHCP = "ipv4";
                      LinkLocalAddressing = "ipv4"; # disable ipv6
                    };
                    dhcpV4Config = {
                      UseDomains = true;
                    } // lib.optionalAttrs (cfg.secondaryInterface.DNS != null) { UseDNS = false; };
                    linkConfig.RequiredForOnline = "carrier";
                  };
                };
            }
        else
          lib.recursiveUpdate cfg.customNetworking { enable = true; };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" = lib.mkIf (
      config.mySystem.impermanence.enable && cfg.wifiSupport
    ) { directories = [ "/etc/NetworkManager" ]; };

    mySystemApps.xorg.userAutorun = lib.optionalAttrs cfg.wifiSupport {
      nm-applet = lib.getExe pkgs.networkmanagerapplet;
    };
  };
}
