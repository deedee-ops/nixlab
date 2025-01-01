{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.nintendo64;
in
{
  options.myRetro.nintendo64 = {
    enable = lib.mkEnableOption "nintendo64" // {
      default = config.myRetro.retrom.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of Nintendo 64 emulator.";
      default = pkgs.simple64;
    };
    saveStatePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to save states directory.";
      default = "${core.savesDir}/${cfg.package.pname}";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    xdg.configFile =
      let
        gamepad =
          if core.gamepad == "dualsense" then
            "0:Sony Interactive Entertainment DualSense Wireless Controller"
          else
            "Auto";
        profile = if core.gamepad == "none" then "Auto" else core.gamepad;
      in
      (lib.optionalAttrs (cfg.package.pname == "simple64") {
        "mupen64plus/input-profiles.ini".source = ./input-profiles.ini;
        "mupen64plus/input-settings.ini".text = ''
          [General]
          version=2

          [Controller1]
          Gamepad=${gamepad}
          Pak=Memory
          Profile=${profile}

          [Controller2]
          Gamepad=Auto
          Pak=Memory
          Profile=Auto

          [Controller3]
          Gamepad=Auto
          Pak=Memory
          Profile=Auto

          [Controller4]
          Gamepad=Auto
          Pak=Memory
          Profile=Auto
        '';
        "mupen64plus/mupen64plus.cfg".text = ''
          [Core]
          Version = 1,010000
          OnScreenDisplay = True
          NoCompiledJump = False
          DisableExtraMem = False
          AutoStateSlotIncrement = False
          CurrentStateSlot = 1
          EnableDebugger = False
          ScreenshotPath = ""
          SaveStatePath = "${cfg.saveStatePath}"
          SaveSRAMPath = "${cfg.saveStatePath}"
          SharedDataPath = ""
          RandomizeInterrupt = True
          GbCameraVideoCaptureBackend1 = ""
          SaveDiskFormat = 1
          SaveFilenameFormat = 1

          [CoreEvents]
          Version = 1
          Kbd Mapping Slot 0 = 48
          Kbd Mapping Slot 1 = 49
          Kbd Mapping Slot 2 = 50
          Kbd Mapping Slot 3 = 51
          Kbd Mapping Slot 4 = 52
          Kbd Mapping Slot 5 = 53
          Kbd Mapping Slot 6 = 54
          Kbd Mapping Slot 7 = 55
          Kbd Mapping Slot 8 = 56
          Kbd Mapping Slot 9 = 57
          Kbd Mapping Stop = 27
          Kbd Mapping Fullscreen = 0
          Kbd Mapping Save State = 286
          Kbd Mapping Load State = 288
          Kbd Mapping Increment Slot = 287
          Kbd Mapping Reset = 290
          Kbd Mapping Speed Down = 291
          Kbd Mapping Speed Up = 292
          Kbd Mapping Screenshot = 293
          Kbd Mapping Pause = 112
          Kbd Mapping Mute = 109
          Kbd Mapping Increase Volume = 93
          Kbd Mapping Decrease Volume = 91
          Kbd Mapping Fast Forward = 102
          Kbd Mapping Speed Limiter Toggle = 0
          Kbd Mapping Frame Advance = 47
          Kbd Mapping Gameshark = 103
          Joy Mapping Stop = ""
          Joy Mapping Fullscreen = ""
          Joy Mapping Save State = ""
          Joy Mapping Load State = ""
          Joy Mapping Increment Slot = ""
          Joy Mapping Reset = ""
          Joy Mapping Speed Down = ""
          Joy Mapping Speed Up = ""
          Joy Mapping Screenshot = ""
          Joy Mapping Pause = ""
          Joy Mapping Mute = ""
          Joy Mapping Increase Volume = ""
          Joy Mapping Decrease Volume = ""
          Joy Mapping Fast Forward = ""
          Joy Mapping Frame Advance = ""
          Joy Mapping Gameshark = ""

          [Video-Parallel]
          Fullscreen = True
          Upscaling = ${
            builtins.toString (
              if core.screenWidth / 640 > core.screenHeight / 480 then
                core.screenHeight / 480
              else
                core.screenWidth / 640
            )
          }
          VSync = True
          ScreenWidth = ${builtins.toString core.screenWidth}
          ScreenHeight = ${builtins.toString core.screenHeight}
          WidescreenStretch = False
          DeinterlaceWeave = False
          SuperscaledReads = False
          SuperscaledDither = True
          SynchronousRDP = True
          CropOverscan = 0
          VerticalStretch = 0
          VIAA = True
          Divot = True
          GammaDither = True
          VIBilerp = True
          VIDither = True
          DownScale = 0
          NativeTextLOD = False
          NativeTextRECT = True
        '';
      })
      // { };
  };
}
