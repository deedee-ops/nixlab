{
  config,
  lib,
  nixConfig,
  ...
}:
let
  cfg = config.mySystem.nix;
  allowedUsers = [
    "root"
    "@wheel"
    config.mySystem.primaryUser
  ];
in
{
  options.mySystem.nix = {
    enableGC = lib.mkEnableOption "nix GC" // {
      default = true;
    };
  };

  config = {
    nix = {
      gc = lib.mkIf cfg.enableGC {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 30d";
      };

      settings = {
        allowed-users = allowedUsers;

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = allowedUsers;

        use-xdg-base-directories = true;
      } // nixConfig;
    };
  };
}
