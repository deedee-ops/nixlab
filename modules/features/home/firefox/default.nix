{ self, ... }:
{
  flake.homeModules.features-home-firefox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.firefox;
      isGPU =
        (builtins.elem "iHD" cfg.features)
        || (builtins.elem "radeon" cfg.features)
        || (builtins.elem "nvidia" cfg.features);
      firefoxPkg = config.programs.firefox.finalPackage;
    in
    {
      options.features.home.firefox = {
        features = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "doh"
              "i915"
              "nvidia"
              "radeon"
            ]
          );
          description = "Extra features enabled in niri configs";
          default = [ ];
        };

        trustedRootCertificates = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "A list of trusted root certificates in PEM format.";
          default = [ ];
        };
      };

      config = {
        stylix.targets.firefox = {
          enable = true;
          profileNames = [ "default" ];
        };

        programs.firefox = {
          enable = true;

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
                "${pkgs.writeText "custom-ca.crt" (builtins.concatStringsSep "\n" cfg.trustedRootCertificates)}"
              ];
            };
          };

          profiles = {
            default = {
              search = {
                force = true;
                default = "ddg";
                order = [ "ddg" ];
                engines = {
                  "ddg" = {
                    urls = [
                      {
                        template = "https://duckduckgo.com/";
                        params = [
                          {
                            name = "q";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                  };
                };
              };
              settings =
                lib.optionalAttrs isGPU {
                  # hardware accelerated video decoding
                  "gfx.webrender.all" = true;
                  "media.av1.enabled" = !(builtins.elem "radeon" cfg.features);
                  "media.ffmpeg.vaapi.enabled" = true;
                  "media.hardware-video-decoding.force-enabled" = true;
                  "media.rdd-ffmpeg.enabled" = true;
                  "widget.dmabuf.force-enabled" = true;
                }
                // lib.optionalAttrs (!(builtins.elem "doh" cfg.features)) {
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
                // lib.optionalAttrs (builtins.elem "doh" cfg.features) {
                  # Variant B: force DNS over HTTPS
                  "network.dns.echconfig.enabled" = true;
                  "network.dns.use_https_rr_as_altsvc" = true;
                  "network.security.esni.enabled" = true;
                  "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
                  "network.trr.default_provider_uri" = "https://dns.quad9.net/dns-query";
                  "network.trr.excluded-domains" = "ajgon.casa";
                  "network.trr.mode" = 3;
                  "network.trr.uri" = "https://dns.quad9.net/dns-query";
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

                  # clipboard
                  "widget.clipboard.use-cached-data.enabled" = true;

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
                        "keepassxc-browser_keepassxc_org-browser-action" # KeepassXC
                      ]
                      ++ (lib.optionals (builtins.elem "obsidian" (map (p: p.pname or false) config.home.packages)) [
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
                  "browser.startup.page" = 1;
                  "browser.startup.homepage" = "https://www.ajgon.casa";
                }
                // lib.optionalAttrs (self.theme.polarity == "dark") { "ui.systemUsesDarkTheme" = 1; };

              id = 0;
              isDefault = true;
              name = "default";
            };
          };
        };

        home = {
          packages = lib.optionals isGPU [ pkgs.ffmpeg-full ];

          sessionVariables = {
            DEFAULT_BROWSER = "${lib.getExe firefoxPkg}";
            MOZ_ENABLE_WAYLAND = "1";
            MOZ_DBUS_REMOTE = "1";
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

        systemd.user.services = lib.mkGuiStartupService { package = firefoxPkg; };
      };
    };
}
