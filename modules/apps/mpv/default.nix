{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.mpv;
in
{
  options.myHomeApps.mpv = {
    enable = lib.mkEnableOption "mpv" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;

      # based on https://github.com/classicjazz/mpv-config/blob/master/mpv.conf
      config = {
        vo = "gpu-next";
        gpu-api = "vulkan";
        hwdec = "auto";

        reset-on-next-file = "audio-delay,mute,pause,speed,sub-delay,video-aspect-override,video-pan-x,video-pan-y,video-rotate,video-zoom,volume";
        framedrop = false;

        # UI
        border = false;
        msg-color = true;
        term-osd-bar = true;
        force-window = "immediate";
        cursor-autohide = 1000;
        geometry = "3840x2160";
        no-hidpi-window-scale = "";

        # Playback
        deinterlace = false;

        # Colorspace
        target-prim = "auto";
        target-trc = "auto";
        vf = "format=colorlevels=full:colormatrix=auto";
        video-output-levels = "full";

        # Dithering
        dither-depth = "auto";
        temporal-dither = true;
        dither = "fruit";

        # Debanding
        deband = true;
        deband-iterations = 4;
        deband-threshold = 35;
        deband-range = 16;
        deband-grain = 5;

        # Motion interpolation
        display-fps-override = 60;
        interpolation = true;
        tscale = "oversample";
        # display-resample kills CPU for some reason
        # video-sync = "display-resample";

        # Anti-ringing
        scale-antiring = 0.6;

        # Theme
        osd-back-color = "#6c7086";
        osd-border-color = "#11111b";
        osd-color = "#cdd6f4";
        osd-shadow-color = "#1e1e2e";
      };

      profiles = {
        "4k60" = {
          profile-desc = "4k60";
          profile-cond = "((width ==3840 and height ==2160) and p[\"estimated-vf-fps\"]>=31)";
          deband = false;
          interpolation = false;
          glsl-shader = "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl";
        };
        "4k30" = {
          profile-desc = "4k30";
          profile-cond = "((width ==3840 and height ==2160) and p[\"estimated-vf-fps\"]<31)";
          deband = false;
          glsl-shader = "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl";
        };
        "full-hd60" = {
          profile-desc = "full-hd60";
          profile-cond = "((width ==1920 and height ==1080) and not p[\"video-frame-info/interlaced\"] and p[\"estimated-vf-fps\"]>=31)";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-lite-ar-r4.hook"
          ];
          interpolation = false;
        };
        "full-hd30" = {
          profile-desc = "full-hd30";
          profile-cond = "((width ==1920 and height ==1080) and not p[\"video-frame-info/interlaced\"] and p[\"estimated-vf-fps\"]<31)";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-lite-ar-r4.hook"
          ];
        };
        "full-hd-interlaced" = {
          profile-desc = "full-hd-interlaced";
          profile-cond = "((width ==1920 and height ==1080) and p[\"video-frame-info/interlaced\"] and p[\"estimated-vf-fps\"]<31)";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-lite-ar-r4.hook"
          ];
          vf = "bwdif=mode=1";
        };
        "hd" = {
          profile-desc = "hd";
          profile-cond = "(width ==1280 and height ==720)";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-zoom-ar-r3.hook"
          ];
        };
        "sdtv-ntsc" = {
          profile-desc = "sdtv-ntsc";
          profile-cond = "((width ==640 and height ==480) or (width ==704 and height ==480) or (width ==720 and height ==480))";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-zoom-ar-r3.hook"
          ];
          vf = "bwdif=mode=1";
        };
        "sdtv-pal" = {
          profile-desc = "sdtv-pal";
          profile-cond = "((width ==352 and height ==576) or (width ==480 and height ==576) or (width ==544 and height ==576) or (width ==720 and height ==576))";
          glsl-shader = [
            "${config.xdg.configHome}/mpv/shaders/CfL_Prediction.glsl"
            "${config.xdg.configHome}/mpv/shaders/ravu-zoom-ar-r3.hook"
          ];
          vf = "bwdif=mode=1";
        };
      };

      bindings = {
        "ctrl+a" = "script-message osc-visibility cycle";
      };

      scripts = [
        pkgs.mpvScripts.mpris
        pkgs.mpvScripts.uosc
        pkgs.mpvScripts.thumbfast
      ];
    };

    xdg.configFile = {
      "mpv/script-opts" = {
        source = ./script-opts;
        recursive = true;
      };
      "mpv/shaders" = {
        source = ./shaders;
        recursive = true;
      };
    };
  };
}
