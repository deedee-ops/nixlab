_: {
  flake.nixosModules.features-nixos-time =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.time;
    in
    {
      options.features.nixos.time = {
        timeZone = lib.mkOption {
          type = lib.types.str;
          description = "Timezone of system.";
          default = "Europe/Warsaw";
        };
        hwClockLocalTime = lib.mkOption {
          type = lib.types.bool;
          description = "If hardware clock is set to local time (useful for windows dual boot).";
          default = false;
        };
      };
      config = {
        time.timeZone = cfg.timeZone;
        time.hardwareClockInLocalTime = cfg.hwClockLocalTime;
      };
    };
}
