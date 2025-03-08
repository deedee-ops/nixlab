{ config, lib, ... }:
let
  cfg = config.mySystemApps.squid;
in
{
  options.mySystemApps.squid = {
    enable = lib.mkEnableOption "squid app";
  };

  config = lib.mkIf cfg.enable {
    services.squid = {
      enable = true;
      extraConfig = ''
        hosts_file /etc/hosts
        shutdown_lifetime 5 seconds
      '';
    };

    nixpkgs.config.permittedInsecurePackages = [ "squid-6.13" ];
  };
}
