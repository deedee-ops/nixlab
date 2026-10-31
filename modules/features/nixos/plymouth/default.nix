{ self, ... }:
{
  flake.nixosModules.features-nixos-plymouth =
    { pkgs, ... }:
    {
      config = {
        stylix.targets.plymouth.enable = false;

        boot = {
          kernelParams = [
            "quiet"
            "systemd.show_status=auto"
            "rd.udev.log_level=3"
          ];
          consoleLogLevel = 0;
          loader.timeout = 2;

          plymouth = {
            enable = true;
            theme = "${self.theme.name}-${self.theme.style}";
            themePackages = [ (pkgs.catppuccin-plymouth.override { variant = self.theme.style; }) ];
          };
        };
      };
    };
}
