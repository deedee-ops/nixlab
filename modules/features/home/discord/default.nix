_: {
  flake.homeModules.features-home-discord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      discordPkg = pkgs.discord.overrideAttrs (oldAttrs: {
        postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
          wrapProgram "$out/opt/Discord/Discord" \
            --set 'HOME' '${config.xdg.configHome}'
        '';
      });
    in
    {
      config = {
        home.packages = [ discordPkg ];

        systemd.user.services = lib.mkGuiStartupService { package = discordPkg; };
      };
    };
}
