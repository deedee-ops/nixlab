_: {
  flake.nixosModules.features-nixos-gaming =
    { config, pkgs, ... }:
    {
      config = {
        users.users."${config.features.nixos.user.name}".extraGroups = [ "gamemode" ];

        programs = {
          gamemode.enable = true;
          steam = {
            enable = true;
            package = pkgs.steam.override { extraArgs = "-system-composer"; };
            gamescopeSession.enable = true;
          };
        };

        environment = {
          systemPackages = [
            pkgs.mangohud
            pkgs.protonup-ng # proton GE
          ];
        };
      };
    };
}
