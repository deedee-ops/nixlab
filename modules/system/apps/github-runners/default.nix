{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.github-runners;
in
{
  options.mySystemApps.github-runners = {
    enable = lib.mkEnableOption "github runners";
    runners = lib.mkOption {
      type = lib.types.int;
      description = "Number of runners";
      default = 4;
    };
    githubTokenSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing cloudflare token.";
      default = "system/apps/github-runners/github_token";
    };
  };

  config =
    let
      paddedNum = n: if n < 10 then "0${builtins.toString n}" else builtins.toString n;

      name = "deedee-ops";
      host = config.networking.hostName;
      user = "github-runner";
      group = "github-runner";
    in
    lib.mkIf cfg.enable {
      sops.secrets."${cfg.githubTokenSopsSecret}" = {
        restartUnits = builtins.map (i: "github-runner-${host}-${name}-${paddedNum i}.service") (
          lib.lists.range 1 cfg.runners
        );
      };

      users = {
        users."${user}" = {
          inherit group;
          isSystemUser = true;
        };
        groups."${group}" = { };
      };
      nix.settings.trusted-users = [ user ];

      services.github-runners = builtins.listToAttrs (
        builtins.map (i: {
          name = "${host}-${name}-${paddedNum i}";
          value = {
            inherit user group;

            enable = true;
            ephemeral = true;
            extraLabels = [ host ];
            extraPackages = [
              pkgs.nix
              pkgs.coreutils
              pkgs.gnutar
              pkgs.jq
              pkgs.which
            ];
            noDefaultLabels = true;
            replace = true;
            tokenFile = config.sops.secrets."${cfg.githubTokenSopsSecret}".path;
            url = "https://github.com/${name}";
          };
        }) (lib.lists.range 1 cfg.runners)
      );
    };
}
