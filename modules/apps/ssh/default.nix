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
    programs = {
      ssh = lib.attrsets.recursiveUpdate {
        enable = true;
        enableDefaultConfig = false;
        package = pkgs.symlinkJoin {
          name = "ssh";
          paths = [
            (pkgs.writeShellScriptBin "ssh" ''
              exec ${lib.getExe pkgs.openssh} -F ${config.xdg.configHome}/ssh/config "$@"
            '')
            (pkgs.writeShellScriptBin "scp" ''
              exec ${lib.getExe' pkgs.openssh "scp"} -F ${config.xdg.configHome}/ssh/config "$@"
            '')
            (pkgs.writeShellScriptBin "sftp" ''
              exec ${lib.getExe' pkgs.openssh "sftp"} -F ${config.xdg.configHome}/ssh/config "$@"
            '')
            (pkgs.writeShellScriptBin "ssh-copy-id" ''
              exec ${lib.getExe' pkgs.openssh "ssh-copy-id"} -F ${config.xdg.configHome}/ssh/config "$@"
            '')
            pkgs.openssh
          ];
        };

        matchBlocks."*" = {
          addKeysToAgent = "8h";
          controlPath = "${config.xdg.stateHome}/ssh/master-%r@%n:%p";
          userKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
        };
      } cfg.appendOptions;
    };

    services.ssh-agent = {
      enable = true;
    };

    home = {
      activation = {
        ssh-state = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.xdg.stateHome}/ssh || true
        '';
      };
    };

    # hack to move ssh config from ~/.ssh/config to ~/.config/ssh/config
    home.file.".ssh/config".enable = false;
    xdg.configFile."ssh/config".text = config.home.file.".ssh/config".text;
  };
}
