{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myApps.gnupg;
in
{
  options.myApps.gnupg = {
    enable = lib.mkEnableEnabledOption "gnupg";
    enableGpgAgent = lib.mkEnableEnabledOption "gpg-agent";
    pinentryPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry;
      description = "Pinentry package.";
    };
    publicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of public keys to be imported.";
    };
    privateKeys = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = "Private key id.";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Private key path.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    myApps.shellInitScriptContents = builtins.map (key: ''
      ${lib.getExe pkgs.gnupg} --list-secret-keys ${key.id} > /dev/null || gpg --batch --import ${key.path}
    '') cfg.privateKeys;

    home.shellAliases.gpgkill = "${lib.getExe' pkgs.gnupg "gpgconf"} --kill gpg-agent";

    programs.gpg = {
      enable = true;

      homedir = "${config.xdg.dataHome}/gnupg";
      mutableKeys = false;
      mutableTrust = false;

      publicKeys = builtins.map (src: {
        source = src;
        trust = "ultimate";
      }) cfg.publicKeys;
    };

    services.gpg-agent = lib.mkIf cfg.enableGpgAgent {
      inherit (cfg) pinentryPackage;

      enable = true;
      enableScDaemon = true;
    };
  };
}
