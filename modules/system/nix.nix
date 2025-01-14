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
    gcPeriod = lib.mkOption {
      type = lib.types.enum [
        "daily"
        "monthly"
      ];
      default = "daily";
    };
    useBetaCache = lib.mkEnableOption "beta cache";
  };

  config = {
    nix = {
      gc = lib.mkIf cfg.enableGC {
        automatic = true;
        dates = cfg.gcPeriod;
        options = "--delete-older-than ${if cfg.gcPeriod == "daily" then "30" else "90"}d";
      };

      settings = {
        allowed-users = allowedUsers;

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = lib.mkIf cfg.useBetaCache (
          lib.mkForce [ "https://aseipp-nix-cache.global.ssl.fastly.net" ]
        );

        trusted-users = allowedUsers;

        use-xdg-base-directories = true;
      } // nixConfig;
    };
  };
}
