{ config, lib, ... }:
let
  cfg = config.myHardware.sound;
in
{
  options.myHardware.sound = {
    enable = lib.mkEnableOption "sound";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      extraConfig.pipewire."auto-switch" = {
        "pulse.cmd" = [
          {
            cmd = "load-module";
            args = "module-switch-on-connect";
          }
        ];
      };

      wireplumber = {
        enable = true;
        extraConfig = {
          "disable-iec958" = {
            "monitor.alsa.rules" = [
              {
                matches = [ { "node.name" = "alsa_output.pci-0000_0c_00.4.iec958-stereo"; } ];
                actions = {
                  update-props = {
                    "node.disabled" = true;
                  };
                };
              }
            ];
          };
        };
      };
    };
    users.users."${config.mySystem.primaryUser}".extraGroups = [ "audio" ];
  };
}
