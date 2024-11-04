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
    githubPrivateTokenSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing access token allowing access to dependent, private github repos.";
    };
  };

  config = {
    sops.secrets."${cfg.githubPrivateTokenSopsSecret}" = {
      owner = "root";
      group = "wheel";
      mode = "0440";
    };

    nix = {
      gc = lib.mkIf cfg.enableGC {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 30d";
      };

      extraOptions = ''
        !include ${config.sops.secrets."${cfg.githubPrivateTokenSopsSecret}".path}
      '';

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
