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
    user = lib.mkOption {
      type = lib.types.str;
      default = "adguardhome";
    };
    adminPasswordSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing admin password.";
    };
    addToHomepage = lib.mkEnableOption "adguard in homepage" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.adminPasswordSopsSecret}".restartUnits = [ "adguardhome.service" ];

    services.adguardhome = {
      enable = true;
      mutableSettings = false;

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
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
          protection_enabled = true;
          filtering_enabled = true;
          upstream_mode = "load_balance";
          upstream_dns = [
            "9.9.9.9"
            "149.112.112.10"
          ];
          bootstrap_dns = [
            "9.9.9.9"
            "149.112.112.10"
          ];
          fallback_dns = [
            "1.1.1.1"
            "1.1.0.0"
          ];
          cache_size = 104857600;
          cache_ttl_min = 60;
          cache_optimistic = true;
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
                name = "AlleBlock";
                url = "https://alleblock.pl/alleblock/alleblock.txt";
              }
              {
                name = "Polskie Filtry Anty-Adblockowe";
                url = "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/anti-adblock.txt";
              }
              {
                name = "(suplement) Polskie Filtry Anty-Adblockowe";
                url = "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/anti-adblock-suplement-adguard.txt";
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
      preStart = lib.mkAfter ''
        HASH="$(cat ${
          config.sops.secrets."${cfg.adminPasswordSopsSecret}".path
        } | ${lib.getExe' pkgs.apacheHttpd "htpasswd"} -niB "" | cut -c 2-)"
        ${lib.getExe pkgs.gnused} -i"" "s,ADGUARDPASS,'$HASH',g" "$STATE_DIRECTORY/AdGuardHome.yaml"
      '';
      serviceConfig.User = cfg.user;
      serviceConfig.Group = "services";
    };

    services = {
      resolved.enable = false;

      nginx.virtualHosts.adguard = svc.mkNginxVHost "adguard" "http://localhost:${builtins.toString config.services.adguardhome.port}";
    };
  };
}
