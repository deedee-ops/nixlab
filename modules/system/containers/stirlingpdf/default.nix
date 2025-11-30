{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.stirlingpdf;
in
{
  options.mySystemApps.stirlingpdf = {
    enable = lib.mkEnableOption "stirlingpdf container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/stirlingpdf";
    };
    ocrLanguages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        Language codes which should be supported by OCR.
        Full list here: <https://github.com/tesseract-ocr/tessdata/>
      '';
      default = [ "pol" ];
      example = [
        "pol"
        "ita"
        "cat"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for stirlingpdf are disabled!") ];

    virtualisation.oci-containers.containers.stirlingpdf = svc.mkContainer {
      cfg = {
        image = "docker.stirlingpdf.com/stirlingtools/stirling-pdf:2.0.2@sha256:af9942975d39b953a008aaa1bb2bbb23330d725d8aeda835eb53de3715e42e36";
        user = "65000:65000";
        environment = {
          ALLOW_GOOGLE_VISIBILITY = "false";
          DISABLE_ADDITIONAL_FEATURES = "true";
          DISABLE_PIXEL = "true";
          LANGS = "en_GB";
          SHOW_SURVEY = "false";
          SYSTEM_DEFAULTLOCALE = "en-US";
          SYSTEM_ENABLEANALYTICS = "false";
          SYSTEM_ENABLEPOSTHOG = "false";
          SYSTEM_ENABLESCARF = "false";
        };
        volumes = [
          "/var/cache/stirlingpdf/training:/usr/share/tessdata"
          "${cfg.dataDir}/configs:/configs"
          "${cfg.dataDir}/customFiles:/customFiles"
          "${cfg.dataDir}/pipeline:/pipeline"
        ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/logs,tmpfs-mode=1777"
        ];
      };
    };

    services = {
      nginx.virtualHosts.stirlingpdf = svc.mkNginxVHost {
        host = "pdf";
        proxyPass = "http://stirlingpdf.docker:8080";
        autheliaIgnorePaths = [ "/api" ];
        extraConfig = ''
          sub_filter "</body>" "<script>jQuery('#footer, .go-pro-badge, .lead.fs-4').remove()</script></body>";
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "stirlingpdf";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-stirlingpdf = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/customFiles" "${cfg.dataDir}/pipeline" "/var/cache/stirlingpdf/training"
        chown 65000:65000 "${cfg.dataDir}" "${cfg.dataDir}/config" "${cfg.dataDir}/customFiles" "${cfg.dataDir}/pipeline"
        chown -R 65000:65000 /var/cache/stirlingpdf
      '';
      postStart = lib.mkAfter (
        ''
          sleep 10
          rm -rf /var/cache/stirlingpdf/training/*.traineddata
          ${lib.getExe pkgs.wget} -O /var/cache/stirlingpdf/training/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/eng.traineddata

          # use only chosen languages
        ''
        + (builtins.concatStringsSep "\n" (
          builtins.map (
            lang:
            "${lib.getExe pkgs.wget} -O /var/cache/stirlingpdf/training/${lang}.traineddata https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/${lang}.traineddata"
          ) cfg.ocrLanguages
        ))
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.StirlingPDF = svc.mkHomepage "stirlingpdf" // {
        icon = "stirling-pdf";
        href = "https://pdf.${config.mySystem.rootDomain}";
        description = "PDF swiss-army knife";
      };
    };
  };
}
