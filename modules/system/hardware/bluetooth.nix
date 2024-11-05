{
  config,
  lib,
  ...
}:
let
  cfg = config.myHardware.bluetooth;
in
{
  options.myHardware.bluetooth = {
    enable = lib.mkEnableOption "bluetooth";
  };

  config = lib.mkIf cfg.enable {
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

    services.blueman.enable = true;

    services.pipewire.wireplumber.extraConfig.bluetoothEnhancements =
      lib.mkIf config.myHardware.sound.enable
        {
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
  };
}
