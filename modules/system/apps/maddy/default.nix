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
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."system/apps/maddy/envfile" = {
      owner = "maddy";
      group = "maddy";
      restartUnits = [ "maddy.service" ];
    };

    services.maddy = {
      enable = true;
      hostname = config.mySystem.rootDomain;
      secrets = [
        config.sops.secrets."system/apps/maddy/envfile".path
        (pkgs.writeText "ingress.env" ''
          DEBUG=no
          INGRESS_DOMAIN=${config.mySystem.rootDomain}
        '')
      ];
      config = builtins.readFile ./maddy.conf;
    };
  };
}
