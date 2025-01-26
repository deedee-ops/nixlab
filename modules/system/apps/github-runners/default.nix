{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.github-runners;
  host = config.networking.hostName;
  user = "github-runner";
  group = "github-runner";

  commonOpts = {
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
  };

  paddedNum = n: if n < 10 then "0${builtins.toString n}" else builtins.toString n;
in
{
  options.mySystemApps.github-runners = {
    enable = lib.mkEnableOption "github runners";
    orgRunners = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            num = lib.mkOption {
              type = lib.types.int;
            };

            githubTokenSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing GitHub token.";
            };
          };
        }
      );
      default = { };
    };

    personalRunners = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            num = lib.mkOption {
              type = lib.types.int;
            };

            githubTokenSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing GitHub token.";
            };
          };
        }
      );

      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      builtins.listToAttrs (
        builtins.map (runnerName: {
          name = cfg.personalRunners."${runnerName}".githubTokenSopsSecret;
          value = {
            restartUnits = builtins.map (
              i:
              "github-runner-${host}-${builtins.replaceStrings [ "/" ] [ "-" ] runnerName}-${paddedNum i}.service"
            ) (lib.lists.range 1 cfg.personalRunners."${runnerName}".num);
          };
        }) (builtins.attrNames cfg.personalRunners)
      )
      // builtins.listToAttrs (
        builtins.map (runnerName: {
          name = cfg.orgRunners."${runnerName}".githubTokenSopsSecret;
          value = {
            restartUnits = builtins.map (i: "github-runner-${host}-${runnerName}-${paddedNum i}.service") (
              lib.lists.range 1 cfg.orgRunners."${runnerName}".num
            );
          };
        }) (builtins.attrNames cfg.orgRunners)
      );

    users = {
      users."${user}" = {
        inherit group;
        isSystemUser = true;
      };
      groups."${group}" = { };
    };
    nix.settings.trusted-users = [ user ];

    services.github-runners = lib.mergeAttrsList (
      (builtins.map (
        name:
        (builtins.listToAttrs (
          builtins.map (i: {
            name = "${host}-${builtins.replaceStrings [ "/" ] [ "-" ] name}-${paddedNum i}";
            value = commonOpts // {
              tokenFile = config.sops.secrets."${cfg.personalRunners."${name}".githubTokenSopsSecret}".path;
              url = "https://github.com/${name}";
            };
          }) (lib.lists.range 1 cfg.personalRunners."${name}".num)
        )

        )
      ) (builtins.attrNames cfg.personalRunners))
      ++ (builtins.map (
        name:
        (builtins.listToAttrs (
          builtins.map (i: {
            name = "${host}-${name}-${paddedNum i}";
            value = commonOpts // {
              tokenFile = config.sops.secrets."${cfg.orgRunners."${name}".githubTokenSopsSecret}".path;
              url = "https://github.com/${name}";
            };
          }) (lib.lists.range 1 cfg.orgRunners."${name}".num)
        ))
      ) (builtins.attrNames cfg.orgRunners))
    );
  };
}
