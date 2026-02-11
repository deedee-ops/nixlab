{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.firefox;
  settings =
    lib.optionalAttrs (osConfig.myHardware.nvidia.enable || osConfig.myHardware.i915.enable) {
      # hardware accelerated video decoding
      "media.ffmpeg.vaapi.enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
      "media.av1.enabled" = true;
      "widget.dmabuf.force-enabled" = true;
      "gfx.x11-egl.force-enabled" = true;

    }
    // lib.optionalAttrs (!cfg.dnsOverHttps.enable) {
      # Variant A: kill DNS over HTTPS
      "network.dns.force_waiting_https_rr" = false;
      "network.dns.upgrade_with_https_rr" = false;
      "network.dns.use_https_rr_as_altsvc" = false;
      "network.security.esni.enabled" = false;
      "network.trr.custom_uri" = "";
      "network.trr.default_provider_uri" = "";
      "network.trr.excluded-domains" = "";
      "network.trr.mode" = 5;
      "network.trr.uri" = "";
    }
    // lib.optionalAttrs cfg.dnsOverHttps.enable {
      # Variant B: force DNS over HTTPS
      "network.dns.echconfig.enabled" = true;
      "network.dns.use_https_rr_as_altsvc" = true;
      "network.security.esni.enabled" = true;
      "network.trr.custom_uri" = cfg.dnsOverHttps.resolver;
      "network.trr.default_provider_uri" = cfg.dnsOverHttps.resolver;
      "network.trr.excluded-domains" = builtins.concatStringsSep "," cfg.dnsOverHttps.excludedDomains;
      "network.trr.mode" = 3;
      "network.trr.uri" = cfg.dnsOverHttps.resolver;
    }
    // {
      # startup
      "browser.newtabpage.enabled" = false;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.newtabpage.activity-stream.default.sites" = "";
      "browser.startup.homepage_override.mstone" = "ignore";
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

      # geolocation
      "geo.provider.network.url" =
        "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
      "geo.provider.ms-windows-location" = false;
      "geo.provider.use_corelocation" = false;
      "geo.provider.use_gpsd" = false;
      "geo.provider.use_geoclue" = false;

      # disable ads
      "extensions.getAddons.showPane" = false;
      "extensions.htmlaboutaddons.recommendations.enabled" = false;
      "browser.discovery.enabled" = false;
      "browser.shopping.experience2023.enabled" = false;

      # telemetry
      "datareporting.policy.dataSubmissionEnabled" = false;
      "datareporting.healthreport.uploadEnabled" = false;
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.server" = "data:,";
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.newProfilePing.enabled" = false;
      "toolkit.telemetry.shutdownPingSender.enabled" = false;
      "toolkit.telemetry.updatePing.enabled" = false;
      "toolkit.telemetry.bhrPing.enabled" = false;
      "toolkit.telemetry.firstShutdownPing.enabled" = false;
      "toolkit.telemetry.coverage.opt-out" = true;
      "toolkit.coverage.opt-out" = true;
      "toolkit.coverage.endpoint.base" = "";
      "browser.ping-centre.telemetry" = false;
      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      "app.shield.optoutstudies.enabled" = false;
      "app.normandy.enabled" = false;
      "app.normandy.api_url" = "";
      "breakpad.reportURL" = "";
      "browser.tabs.crashReporting.sendReport" = false;
      "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
      "dom.private-attribution.submission.enabled" = false;

      # location bar
      "browser.urlbar.speculativeConnect.enabled" = false;
      "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
      "browser.urlbar.suggest.quicksuggest.sponsored" = false;
      "browser.urlbar.trending.featureGate" = false;
      "browser.urlbar.addons.featureGate" = false;
      "browser.urlbar.mdn.featureGate" = false;
      "browser.urlbar.pocket.featureGate" = false;
      "browser.urlbar.weather.featureGate" = false;
      "browser.formfill.enable" = false;
      "browser.search.separatePrivateDefault" = true;
      "browser.search.separatePrivateDefault.ui.enabled" = true;
      "network.IDN_show_punycode" = true;

      # passwords
      "signon.autofillForms" = false;
      "signon.formlessCapture.enabled" = false;
      "signon.rememberSignons" = false;
      "network.auth.subresource-http-auth-allow" = 1;

      # downloads
      "browser.download.useDownloadDir" = false;
      "browser.download.alwaysOpenPanel" = false;
      "browser.download.manager.addToRecentDocs" = false;
      "browser.download.always_ask_before_handling_new_types" = true;

      # tracking
      "browser.contentblocking.category" = "strict";

      # containers
      "privacy.userContext.enabled" = true;
      "privacy.userContext.ui.enabled" = true;

      # translations
      "browser.translations.enable" = false;
      "browser.translations.automaticallyPopup" = false;

      # disable AI bullshit
      "browser.ml.chat.enabled" = false;
      "browser.ml.chat.menu" = false;
      "browser.ml.chat.page" = false;
      "browser.ml.chat.shortcuts" = false;
      "browser.ml.chat.sidebar" = false;
      "browser.ml.enable" = false;
      "browser.ml.linkPreview.enabled" = false;
      "browser.ml.pageAssist.enabled" = false;
      "browser.ml.smartAssist.enabled" = false;
      "browser.search.visualSearch.featureGate" = false;
      "browser.tabs.groups.smart.enabled" = false;
      "browser.urlbar.quicksuggest.mlEnabled" = false;
      "extensions.ml.enabled" = false;
      "pdfjs.enableAltText" = false;
      "places.semanticHistory.featureGate" = false;
      "sidebar.revamp" = false;

      # UI
      "browser.uiCustomization.state" = builtins.toJSON {
        placements = {
          widget-overflow-fixed-list = [ ];
          nav-bar = [
            "back-button"
            "forward-button"
            "stop-reload-button"
            "customizableui-special-spring1"
            "urlbar-container"
            "customizableui-special-spring2"
            "downloads-button"
            "fxa-toolbar-menu-button"

            # Extensions
            "foxyproxy_eric_h_jung-browser-action" # FoxyProxy
            "containerise_kinte_sh-browser-action" # Containerise
            "_15b1b2af-e84a-4c70-ac7c-5608b0eeed5a_-browser-action" # Cookiebro
            "ublock0_raymondhill_net-browser-action" # uBlock origin
          ]
          ++ (lib.optionals config.myHomeApps.obsidian.enable [
            "clipper_obsidian_md-browser-action" # obsidian clipper
          ])
          ++ [
            "unified-extensions-button"
          ];
          toolbar-menubar = [ "menubar-items" ];
          TabsToolbar = [
            "tabbrowser-tabs"
            "new-tab-button"
            "alltabs-button"
          ];
          PersonalToolbar = [ ];
        };
        currentVersion = 20;
        newElementCount = 5;
      };

      # misc
      "browser.aboutConfig.showWarning" = false;
      "browser.helperApps.deleteTempFileOnExit" = true;
      "browser.uitour.enabled" = false;
      "dom.security.https_only_mode" = true;
      "network.dns.disableIPv6" = true;
    }
    // lib.optionalAttrs (config.stylix.polarity == "dark") { "ui.systemUsesDarkTheme" = 1; }
    // lib.optionalAttrs (cfg.syncServerUrl != null) {
      "identity.sync.tokenserver.uri" = "${cfg.syncServerUrl}/1.0/sync/1.5";
    }
    // lib.optionalAttrs (cfg.startupPage != null) {
      "browser.startup.page" = 1;
      "browser.startup.homepage" = cfg.startupPage;
    }
    // cfg.extraConfig;
in
{
  options.myHomeApps.firefox = {
    enable = lib.mkEnableOption "firefox";
    dnsOverHttps = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "DNS over HTTPS";
          excludedDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "List of domains excluded from DoH";
            default = [ ];
          };
          resolver = lib.mkOption {
            type = lib.types.str;
            description = "DoH resolver.";
            default = "https://dns.quad9.net/dns-query";
          };
        };
      };
      default = {
        enable = false;
        excludedDomains = [ ];
      };
    };
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      description = "Extra settings for about:config";
      default = { };
    };
    startupPage = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Startup page";
      default = null;
    };
    syncServerUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Sync server URL (without path).";
      default = null;
    };
    whoogleSearch = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "whoogle search";
          url = lib.mkOption {
            type = lib.types.str;
            description = "Whoogle search URL (without path).";
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.firefox = {
      enable = true;
      profileNames = [ "default" ];
    };

    programs.firefox = {
      enable = true;
      package = pkgs.firefox.overrideAttrs (a: {
        buildCommand =
          a.buildCommand
          + (
            ''
              wrapProgram "$executablePath" \
            ''
            + (lib.optionalString osConfig.myHardware.i915.enable ''
              --set 'LIBVA_DRIVER_NAME' 'i965' \
              --set 'LIBVA_DRIVERS_PATH' '${pkgs.intel-vaapi-driver}/lib/dri/' \
            '')
            + ''
              --set 'HOME' '${config.xdg.configHome}'
            ''
          );
      });

      policies = {
        DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "default-off";
        HttpsOnlyMode = "enabled";
        SearchBar = "unified";
        Certificates = {
          Install = [
            "${pkgs.writeText "custom-ca.crt" (
              builtins.concatStringsSep "\n" osConfig.mySystem.trustedRootCertificates
            )}"
          ];
        };
      };

      profiles = {
        default = {
          inherit settings;

          id = 0;
          isDefault = true;
          name = "default";
          search = lib.mkIf cfg.whoogleSearch.enable {
            force = true;
            default = "Whoogle";
            order = [ "Whoogle" ];
            engines = {
              "Whoogle" = {
                urls = [
                  {
                    template = "${cfg.whoogleSearch.url}/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.fetchurl {
                  url = "https://raw.githubusercontent.com/benbusby/whoogle-search/main/app/static/img/favicon/favicon-96x96.png";
                  sha256 = "sha256-erYXYw3N+QBHh35TaI6n+YWMZUQSlN/66SIKMDcnHbA=";
                }}";
              };
            };
          };
        };
      };
    };

    home = {
      file =
        builtins.listToAttrs (
          lib.lists.flatten (
            builtins.map
              (file: [
                {
                  name = ".mozilla/firefox/${file}";
                  value.enable = false;
                }
                {
                  name = ".config/mozilla/firefox/${file}";
                  value.text = config.home.file.".mozilla/firefox/${file}".text;
                }
              ])
              [
                "profiles.ini"
                "default/.keep"
                "default/user.js"
              ]
          )
        )
        // lib.optionalAttrs cfg.whoogleSearch.enable {
          ".mozilla/firefox/default/search.json.mozlz4".enable = lib.mkForce false;
          ".config/mozilla/firefox/default/search.json.mozlz4" = {
            inherit (config.home.file.".mozilla/firefox/default/search.json.mozlz4") source;
            force = true;
          };
        }
        // {
          ".config/.mozilla".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/mozilla";
          ".mozilla/native-messaging-hosts".enable = lib.mkForce false;
        };

      packages = lib.mkIf osConfig.myHardware.nvidia.enable [ pkgs.ffmpeg-full ];

      sessionVariables = {
        DEFAULT_BROWSER = "${lib.getExe config.programs.firefox.finalPackage}";
      }
      // lib.optionalAttrs osConfig.myHardware.nvidia.enable {
        MOZ_DISABLE_RDD_SANDBOX = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        LIBVA_DRIVERS_PATH = "${pkgs.nvidia-vaapi-driver}/lib/dri/";
        NVD_BACKEND = "direct";
      }
      // lib.optionalAttrs osConfig.myHardware.i915.enable {
        MOZ_DISABLE_RDD_SANDBOX = "1";
        NVD_BACKEND = "direct";
      };
    };

    xdg.mimeApps = {
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };
}
