_: {
  flake.homeModules.features-home-obsidian =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      obsidianPkg = pkgs.obsidian.overrideAttrs (oldAttrs: {
        postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
          wrapProgram "$out/bin/obsidian" \
            --set 'HOME' '${config.xdg.configHome}'
        '';
      });
    in
    {
      config = {
        home.packages = [ obsidianPkg ];

        systemd.user.services = lib.mkGuiStartupService { package = obsidianPkg; };
      };
    };
}
