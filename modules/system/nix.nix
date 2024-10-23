{ config, lib, ... }:
let
  cfg = config.mySystem.nix;
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
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://cache.garnix.io"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        builders-use-substitutes = true;
        connect-timeout = 25;
        warn-dirty = false;

        trusted-users = [
          "root"
          "@wheel"
          config.mySystem.primaryUser
        ];

        use-xdg-base-directories = true;
      };
    };
  };
}
