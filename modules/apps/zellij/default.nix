{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.zellij;
in
{
  options.myHomeApps.zellij = {
    enable = lib.mkEnableOption "zellij";
    autoStart = lib.mkEnableOption "zellij autostart and autoattach" // {
      default = true;
    };
    singleInstance = lib.mkEnableOption "zellij keep single instance between multiple sessions" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.zellij.enable = true;

    programs.zellij = {
      enable = true;
      enableZshIntegration = false; # broken for some reason
      settings =
        {
          default_layout = "compact";
          default_mode = "locked";
          mouse_mode = true;
          pane_frames = false;
          scroll_buffer_size = config.myHomeApps.theme.terminalScrollBuffer;
          show_startup_tips = false;
        }
        // lib.optionalAttrs cfg.singleInstance {
          keybinds = {
            shared_among = {
              _args = [
                "normal"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl d" ];
                Detach = { };
              };
            };
          };
        };
    };

    programs.zsh.initContent = lib.mkIf cfg.autoStart (
      lib.mkOrder 100 ''
        export ZELLIJ_AUTO_ATTACH="${if cfg.singleInstance then "true" else "false"}";
        export ZELLIJ_AUTO_EXIT="true";

        eval "$(${lib.getExe config.programs.zellij.package} setup --generate-auto-start zsh)"
      ''
    );
  };
}
