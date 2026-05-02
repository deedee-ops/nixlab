{ self, ... }:
{
  flake.homeModules.features-home-shell = _: {
    imports = [
      self.homeModules.features-home-telemetry
      self.homeModules.features-home-xdg
    ];
  };
}
