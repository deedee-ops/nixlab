{
  config,
  pkgs,
  lib,
  ...
}:
let
  binaryName = "Discord";
  cfg = config.myHomeApps.discord;
  discordPkg = pkgs.discord.overrideAttrs (oldAttrs: {
    postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
      wrapProgram "$out/opt/${binaryName}/${binaryName}" \
        --set 'HOME' '${config.xdg.configHome}'
    '';
  });
in
{
  options.myHomeApps.discord = {
    enable = lib.mkEnableOption "discord";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        discordPkg # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe discordPkg) ];
        awfulRules = [
          {
            rule = {
              class = "discord";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " 0 ";
            };
          }
        ];
      };
      allowUnfree = [ "discord" ];
    };
  };
}
