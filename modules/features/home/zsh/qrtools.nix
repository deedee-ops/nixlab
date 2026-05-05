_: {
  flake.homeModules.features-home-zsh-qrtools =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.zsh.qrcp;
    in
    {
      options.features.home.zsh = {
        qrcp = lib.mkOption {
          type = lib.types.submodule {
            options = {
              port = lib.mkOption {
                type = lib.types.port;
                default = 55555;
                description = "Port qrcp will listen on";
              };
              interface = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Interface qrcp will listen on";
              };
            };
          };
        };
      };
      config = {
        home.shellAliases = {
          qrsend = "${lib.getExe pkgs.qrcp}${
            lib.optionalString (cfg.interface != null) " -i ${cfg.interface}"
          } -p ${builtins.toString cfg.port} send";
          qrrecv = "${lib.getExe pkgs.qrcp}${
            lib.optionalString (cfg.interface != null) " -i ${cfg.interface}"
          } -p ${builtins.toString cfg.port} receive";
          qr = "${lib.getExe pkgs.qrencode} -t ANSI256UTF8";
        };
      };
    };
}
