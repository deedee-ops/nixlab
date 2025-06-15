{ config, lib, ... }:
let
  cfg = config.mySystemApps.lnxlink;
in
{
  options.mySystemApps.lnxlink = {
    enable = lib.mkEnableOption "lnxlink";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of lnxlink.";
      default = pkgs.callPackage ../../pkgs/lnxlink.nix { };
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        Configuration for lnxlink matching config file format.
        See <https://bkbilly.gitbook.io/lnxlink/configuration>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      lnxlink = {
        path = [ cfg.package ];
        description = "lnxlink daemon";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} -c ${pkgs.writeText "config.yaml" (builtins.toJson cfg.settings)}";
        };
      };
    };
  };
}
