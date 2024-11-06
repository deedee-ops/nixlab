{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.ssh;
in
{
  options.myHomeApps.ssh = {
    enable = lib.mkEnableOption "ssh" // {
      default = true;
    };
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
      userKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
    } cfg.appendOptions;

    services.ssh-agent = {
      enable = true;
    };

    home = {
      activation = {
        ssh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.xdg.stateHome}/ssh || true
        '';
      };
    };
  };
}
