_: {
  flake.homeModules.features-home-zathura =
    { config, lib, ... }:
    {
      config = {
        stylix.targets.zathura.enable = !config.programs.noctalia-shell.enable;
        programs.noctalia-shell.settings.templates.activeTemplates = [
          {
            enabled = true;
            id = "zathura";
          }
        ];

        programs.zathura = {
          enable = true;
          extraConfig = lib.optionalString config.programs.noctalia-shell.enable ''
            include noctaliarc
          '';
        };
      };
    };
}
