_: {
  flake.homeModules.features-home-obsidian =
    { pkgs, lib, ... }:
    {
      config = {
        home.packages = [ pkgs.obsidian ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.obsidian; };
      };
    };
}
