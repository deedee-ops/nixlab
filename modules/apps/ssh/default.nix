{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myApps.ssh;
in
{
  options.myApps.ssh = {
    enable = lib.mkEnableEnabledOption "ssh";
    appendOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra custom options which will be merged with programs.ssh.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = lib.attrsets.recursiveUpdate {
      enable = true;
      package = pkgs.openssh;

      addKeysToAgent = "8h";
    } cfg.appendOptions;

    services.ssh-agent = {
      enable = true;
    };
  };
}
