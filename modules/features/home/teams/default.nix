_: {
  flake.homeModules.features-home-teams =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        home.packages = [ pkgs.teams-for-linux ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.teams-for-linux; };
      };
    };
}
