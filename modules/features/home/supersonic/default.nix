{ self, ... }:
{
  flake.homeModules.features-home-supersonic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config =
        let
          supersonicPkg = pkgs.supersonic;
        in
        {
          home.packages = [ supersonicPkg ];

          xdg.configFile =
            let
              configBase = builtins.fromTOML (builtins.readFile ./config.toml);
            in
            {
              "supersonic/config.toml".source = (pkgs.formats.toml { }).generate "config.yaml" (
                lib.recursiveUpdate configBase {
                  Application = {
                    LastCheckedVersion = "v${supersonicPkg.version}";
                    LastLaunchedVersion = "v${supersonicPkg.version}";
                  };

                  Servers = [
                    (
                      (builtins.elemAt configBase.Servers 0)
                      // {
                        Hostname = "https://navidrome.ajgon.casa";
                        Username = "ajgon";
                      }
                    )
                  ];

                  Theme = {
                    ThemeFile = "${self.theme.name}-${self.theme.style}-${self.theme.accent}.toml";
                    Apperance = if self.theme.style == "dark" then "Dark" else "Light";
                  };
                }
              );
              "supersonic/themes/catppuccin-mocha-blue.toml".source = ./catppuccin-mocha-blue.toml;
            };

          systemd.user.services = lib.mkGuiStartupService {
            package = supersonicPkg;
            command = "${lib.getExe supersonicPkg} -start-minimized";
          };
        };
    };
}
