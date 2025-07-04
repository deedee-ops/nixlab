{
  config,
  lib,
  ...
}:
let
  cfg = config.mySystemApps.nfs;
in
{
  options.mySystemApps.nfs = {
    enable = lib.mkEnableOption "NFS exports";
    exports = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Contents of the /etc/exports file.  See
        {manpage}`exports(5)` for the format.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      inherit (cfg) exports;
      enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 2049 ];
  };
}
