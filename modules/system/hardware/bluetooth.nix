{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.bluetooth;
in
{
  options.myHardware.bluetooth = {
    enable = lib.mkEnableOption "bluetooth";
    trust = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of bluetooth devices mac addresses to be automatically trusted.";
      default = [ ];
      example = [ "AA:BB:CC:DD:EE:FF" ];
    };
    wakeFromSuspend = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "wake up from suspend";
          vendorID = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Vendor ID of bluetooth controller.";
          };
          productID = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Product ID of bluetooth controller.";
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.wakeFromSuspend.enable) || (cfg.wakeFromSuspend.vendorID != null);
        message = "When wakeFromSuspend is enabled, vendorID must be set.";
      }
      {
        assertion = (!cfg.wakeFromSuspend.enable) || (cfg.wakeFromSuspend.productID != null);
        message = "When wakeFromSuspend is enabled, productID must be set.";
      }
    ];

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # settings = {
      #   General = {
      #     ControllerMode = "bredr";
      #     Enable = "Source,Sink,Media,Socket";
      #     Experimental = "true";
      #   };
      # };
    };

    services = {

      blueman.enable = true;

      pipewire.wireplumber.extraConfig.bluetoothEnhancements = lib.mkIf config.myHardware.sound.enable {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.autoswitch-profile" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
            "a2dp_sink"
          ];
        };
      };

      udev.extraRules = lib.mkIf cfg.wakeFromSuspend.enable ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0aaa" RUN+="/bin/sh -c 'echo enabled > /sys$env{DEVPATH}/../power/wakeup;'
      '';
    };
    homeApps.awesome.autorun = [ (lib.getExe' pkgs.blueman "blueman-applet") ];

    system.activationScripts = {
      bluez-autotrust = lib.concatStringsSep "\n" (
        builtins.map (trusted: "${lib.getExe' pkgs.bluez "bluetoothctl"} trust ${trusted}") cfg.trust
      );
    };
  };
}
