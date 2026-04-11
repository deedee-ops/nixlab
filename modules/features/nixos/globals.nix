_: {
  flake.nixosModules.features-nixos-globals =
    { lib, ... }:
    {
      options.features.nixos.globals = {
        theme = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = "Theme name";
                default = null;
              };
              style = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = "Theme style";
                default = null;
              };
            };
          };
        };
      };
    };
}
