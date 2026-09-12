_: {
  flake.homeModules.features-home-zathura =
    { config, lib, ... }:
    {
      config = {
        stylix.targets.zathura.enable = !config.programs.noctalia.enable;
        programs.noctalia.settings.theme.templates.community_ids = [ "zathura" ];

        programs.zathura = {
          enable = true;
          extraConfig = lib.optionalString config.programs.noctalia.enable ''
            include noctaliarc
          '';
        };
      };
    };
}
