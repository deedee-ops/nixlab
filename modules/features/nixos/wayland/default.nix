_: {
  flake.nixosModules.features-nixos-wayland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.wayland;
    in
    {
      options.features.nixos.wayland = {
        compositor = lib.mkOption {
          type = lib.types.enum [ "niri" ];
          description = "Compositor to use.";
          default = "niri";
          example = "niri";
        };
      };
      config = {
        environment.systemPackages = [
          pkgs.wl-clipboard
        ];

        security.pam.services.login = { };

        services.gnome.gnome-keyring.enable = lib.mkForce (
          !(builtins.any (key: config.home-manager.users.${key}.programs.keepassxc.enable) (
            builtins.attrNames config.home-manager.users
          ))
        );

        programs."${cfg.compositor}".enable = true;
      };
    };
}
