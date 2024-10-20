{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.maddy;
in
{
  options.mySystemApps.maddy = {
    enable = lib.mkEnableOption "maddy";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing environment variables.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = {
      owner = "maddy";
      group = "maddy";
      restartUnits = [ "maddy.service" ];
    };

    services.maddy = {
      enable = true;
      hostname = config.mySystem.rootDomain;
      secrets = [
        config.sops.secrets."${cfg.envFileSopsSecret}".path
        (pkgs.writeText "ingress.env" ''
          DEBUG=no
          INGRESS_DOMAIN=${config.mySystem.rootDomain}
        '')
      ];
      config = builtins.readFile ./maddy.conf;
    };
  };
}
