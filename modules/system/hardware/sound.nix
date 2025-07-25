{ config, lib, ... }:
let
  cfg = config.myHardware.sound;
in
{
  options.myHardware.sound = {
    enable = lib.mkEnableOption "sound";
    muteOnStart = lib.mkEnableOption "mute default sink on desktop start";
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
    systemd.user.services.wireplumber.postStart = lib.mkAfter ''
      set +e

      for ((i=1; i<=5; i++)); do
          ${lib.getExe' config.services.pipewire.wireplumber.package "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ 1
          if [ $? -eq 0 ]; then
              exit 0
          fi
          if [ $i -lt 5 ]; then
              sleep 0.5
          else
              exit 1
          fi
      done
    '';
  };
}
