{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.adguardhome;
in
{
  options.mySystemApps.adguardhome = {
    enable = lib.mkEnableOption "adguardhome";
    enableDoH = lib.mkEnableOption "DNS over HTTPS server";
    user = lib.mkOption {
      type = lib.types.str;
      default = "adguardhome";
    };
    customMappings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Custom domain mappings to targets.";
      example = {
        "mydomain.example.com" = "192.168.1.2";
      };
      default = { };
    };
    upstreamDNS = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Upstream DNS for Adguard.";
      default = [
        "https://dns.quad9.net/dns-query"
        "[/${config.mySystem.rootDomain}/]${config.myInfra.machines.unifi.ip}"
        "[/relay.${config.mySystem.rootDomain}/]1.1.1.1"
        "[/home.arpa/]${config.myInfra.machines.unifi.ip}"
      ];
    };
    adminPasswordSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing admin password.";
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain for ${config.mySystem.rootDomain}.";
      default = "adguard";
    };
  };

  config =
    let
      webUIIP = config.mySystemApps.docker.network.public.hostIP;
    in
    lib.mkIf cfg.enable {
      sops.secrets."${cfg.adminPasswordSopsSecret}".restartUnits = [ "adguardhome.service" ];

      services.adguardhome = {
        enable = true;
        mutableSettings = false;

        host = webUIIP;

        settings = {
          users = [
            {
              name = "admin";
              password = "ADGUARDPASS"; # placeholder
            }
          ];

          auth_attempts = 3;
          block_auth_min = 3600;

          theme = if config.stylix.polarity == "either" then "auto" else "${config.stylix.polarity}";

          dns = {
            bind_hosts = "BINDHOST";
            port = 53;
            protection_enabled = true;
            filtering_enabled = true;
            upstream_mode = "load_balance";
            upstream_dns = cfg.upstreamDNS;
            bootstrap_dns = [
              "9.9.9.9"
              "149.112.112.10"
            ];
            fallback_dns = [
              "https://security.cloudflare-dns.com/dns-query"
              "https://wikimedia-dns.org/dns-query"
            ];
            use_private_ptr_resolvers = true;
            local_ptr_upstreams = [ config.myInfra.machines.unifi.ip ];
            aaaa_disabled = true;
            cache_size = 104857600;
            cache_ttl_min = 60;
            cache_optimistic = true;
          };

          filtering = {
            rewrites = builtins.map (domain: {
              inherit domain;
              answer = builtins.getAttr domain cfg.customMappings;
            }) (builtins.attrNames cfg.customMappings);
          };

          tls = lib.optionalAttrs cfg.enableDoH {
            enabled = true;
            port_https = 4444;
            port_dns_over_tls = 0;
            port_dns_over_quic = 0;
            port_dnscrypt = 0;
            certificate_path = "${
              config.security.acme.certs."wildcard.${config.mySystem.rootDomain}".directory
            }/fullchain.pem";
            private_key_path = "${
              config.security.acme.certs."wildcard.${config.mySystem.rootDomain}".directory
            }/key.pem";
          };

          filters =
            let
              urls = [
                {
                  name = "AdGuard DNS filter";
                  url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
                }
                {
                  name = "AdAway Default Blocklist";
                  url = "https://adaway.org/hosts.txt";
                }
                {
                  name = "Big OISD";
                  url = "https://big.oisd.nl";
                }
                {
                  name = "Game Console Adblock List";
                  url = "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/GameConsoleAdblockList.txt";
                }
                {
                  name = "WindowsSpyBlocker - Hosts spy rules";
                  url = "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt";
                }
                {
                  name = "Perflyst and Dandelion Sprout's Smart-TV Blocklist";
                  url = "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV-AGH.txt";
                }
                {
                  name = "Mobile Filter";
                  url = "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt";
                }
                {
                  name = "Fanboy's Social Blocking List";
                  url = "https://secure.fanboy.co.nz/fanboy-social.txt";
                }
                {
                  name = "Web Annoyances Ultralist";
                  url = "https://raw.githubusercontent.com/yourduskquibbles/webannoyances/master/ultralist.txt";
                }
                {
                  name = "NoCoin Filter List";
                  url = "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt";
                }
                {
                  name = "I don't care about cookies";
                  url = "https://www.i-dont-care-about-cookies.eu/abp/";
                }
                {
                  name = "osint";
                  url = "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt";
                }
                {
                  name = "phishing army";
                  url = "https://phishing.army/download/phishing_army_blocklist_extended.txt";
                }
                {
                  name = "notrack malware";
                  url = "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt";
                }
                {
                  name = "EasyPrivacy";
                  url = "https://v.firebog.net/hosts/Easyprivacy.txt";
                }
                {
                  name = "Oficjalne Polskie Filtry do AdBlocka, uBlocka Origin i AdGuarda";
                  url = "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-adblock-filters/adblock.txt";
                }
                {
                  name = "(suplement) Oficjalne Polskie Filtry do AdBlocka, uBlocka Origin i AdGuarda";
                  url = "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-adblock-filters/adblock_adguard.txt";
                }
                {
                  name = "Polskie Filtry Społecznościowe";
                  url = "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/adblock_social_filters/adblock_social_list.txt";
                }
                {
                  name = "(suplement) Polskie Filtry Społecznościowe";
                  url = "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/adblock_social_filters/social_filters_uB_AG.txt";
                }
                {
                  name = "Polskie Filtry Elementów Irytujących";
                  url = "https://raw.githubusercontent.com/FiltersHeroes/PolishAnnoyanceFilters/master/PPB.txt";
                }
                {
                  name = "(suplement) Polskie Filtry Elementów Irytujących";
                  url = "https://raw.githubusercontent.com/FiltersHeroes/PolishAnnoyanceFilters/master/PAF_supp.txt";
                }
                {
                  name = "Polski Antyirytujący Dodatek Specjalny";
                  url = "https://raw.githubusercontent.com/FiltersHeroes/PolishAntiAnnoyingSpecialSupplement/master/polish_rss_filters.txt";
                }
                {
                  name = "KAD - Przekręty";
                  url = "https://raw.githubusercontent.com/FiltersHeroes/KAD/master/KAD.txt";
                }
                {
                  name = "Polskie Filtry Prywatności";
                  url = "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/adblock.txt";
                }
                {
                  name = "Polskie Filtry Anty-Adblockowe";
                  url = "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/anti-adblock.txt";
                }
                {
                  name = "(suplement) Polskie Filtry Anty-Adblockowe";
                  url = "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/anti-adblock-suplement-adguard.txt";
                }
                {
                  name = "OCSP Responder Blocklist";
                  url = "https://raw.githubusercontent.com/ScottHelme/revocation-endpoints/refs/heads/master/ocsp.txt";
                }
                {
                  name = "CRL Server Blocklist";
                  url = "https://raw.githubusercontent.com/ScottHelme/revocation-endpoints/refs/heads/master/crl.txt";
                }
              ];

              buildList = id: url: {
                enabled = true;
                inherit id;
                inherit (url) name;
                inherit (url) url;
              };
            in
            lib.imap1 buildList urls;
        };
      };

      users.users.${cfg.user} = {
        isSystemUser = true;
        group = "services";
      };

      systemd.services.adguardhome = {
        # if you have issues with adguard not accepting the password,
        # ensure that cfg.adminPasswordSopsSecret file on the remote machine is readable by services group!
        preStart = lib.mkAfter (
          ''
            HASH="$(cat ${
              config.sops.secrets."${cfg.adminPasswordSopsSecret}".path
            } | ${lib.getExe' pkgs.apacheHttpd "htpasswd"} -niB "" | cut -c 2-)"
            MAINIP="$(${lib.getExe' pkgs.iproute2 "ip"} -4 addr show dev ${config.mySystem.networking.rootInterface} | grep -Po 'inet \K[\d.]+')"
            BINDHOST="['$MAINIP']"
          ''
          + (lib.optionalString (config.mySystem.networking.secondaryInterface != null) ''
            SECONDARYIP="$(${lib.getExe' pkgs.iproute2 "ip"} -4 addr show dev ${config.mySystem.networking.secondaryInterface.name} | grep -Po 'inet \K[\d.]+')"
            BINDHOST="['$MAINIP','$SECONDARYIP']"
          '')
          + ''
            cat "$STATE_DIRECTORY/AdGuardHome.yaml" > "$STATE_DIRECTORY/debug-pre.yaml"
            echo "$HASH" > "$STATE_DIRECTORY/hash"
            ${lib.getExe pkgs.gnused} -i"" "s#ADGUARDPASS#'$HASH'#g" "$STATE_DIRECTORY/AdGuardHome.yaml"
            ${lib.getExe pkgs.gnused} -i"" "s#BINDHOST#$BINDHOST#g" "$STATE_DIRECTORY/AdGuardHome.yaml"

            cat "$STATE_DIRECTORY/AdGuardHome.yaml" > "$STATE_DIRECTORY/debug.yaml"
          ''
        );
        serviceConfig.User = cfg.user;
        serviceConfig.Group = "services";
      };

      services.nginx.virtualHosts.adguard = svc.mkNginxVHost {
        host = cfg.subdomain;
        proxyPass =
          if cfg.enableDoH then
            "https://${webUIIP}:4444"
          else
            "http://${webUIIP}:${builtins.toString config.services.adguardhome.port}";
        useAuthelia = false;
      };

      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 3000 ];

      mySystemApps.homepage = {
        services.Apps.AdGuardHome = svc.mkHomepage cfg.subdomain // {
          icon = "adguard-home.svg";
          container = null;
          description = "Adguard filtering DNS";
          widget = {
            type = "adguard";
            url = "http://${webUIIP}:${builtins.toString config.services.adguardhome.port}";
            username = "admin";
            password = "@@ADGUARD_PASSWORD@@";
            fields = [
              "queries"
              "blocked"
              "filtered"
              "latency"
            ];
          };
        };
        secrets.ADGUARD_PASSWORD = config.sops.secrets."${cfg.adminPasswordSopsSecret}".path;
      };
    };
}
