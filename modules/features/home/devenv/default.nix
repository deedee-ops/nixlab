_: {
  flake.homeModules.features-home-devenv =
    { pkgs, lib, ... }:
    {
      config = {
        home.packages = [ pkgs.devenv ];

        programs.zsh.initContent = lib.mkOrder 1000 ''
          eval "$(${lib.getExe pkgs.devenv} hook zsh)"
        '';
      };
    };
}
