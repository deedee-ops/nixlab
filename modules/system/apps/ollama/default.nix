{ config, lib, ... }:
let
  cfg = config.mySystemApps.ollama;
in
{
  options.mySystemApps.ollama = {
    enable = lib.mkEnableOption "ollama";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      user = "ollama";
      group = "ollama";
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              inherit (config.services.ollama) user group;
              directory = config.services.ollama.home;
              mode = "750";
            }
          ];
        };

    systemd.services.ollama.serviceConfig = lib.optionalAttrs config.mySystem.impermanence.enable {
      StateDirectory = lib.mkForce "";
    };

    mySystem.allowUnfree = [
      "cudnn"
    ];
  };
}
