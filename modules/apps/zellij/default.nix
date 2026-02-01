{
  osConfig,
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
      settings = {
        default_layout = "compact";
        default_mode = "locked";
        mouse_mode = true;
        pane_frames = false;
        scroll_buffer_size = config.myHomeApps.theme.terminalScrollBuffer;
        show_startup_tips = false;
      }
      // lib.optionalAttrs cfg.singleInstance {
        keybinds =
          let
            detachBind = {
              bind = {
                _args = [ "Ctrl d" ];
                _children = [
                  {
                    Detach = { };
                  }
                ];
              };
            };
          in
          {
            locked._children = [
              {
                unbind._args = [ "Ctrl g" ];
              }
              {
                bind = {
                  _args = [ "Ctrl /" ];
                  _children = [
                    {
                      SwitchToMode._args = [ "normal" ];
                    }
                  ];
                };
              }
              detachBind
            ];
            normal._children = [
              {
                unbind._args = [ "Ctrl g" ];
              }
              {
                bind = {
                  _args = [ "Ctrl /" ];
                  _children = [
                    {
                      SwitchToMode._args = [ "locked" ];
                    }
                  ];
                };
              }
              detachBind
            ];
          };
      };
    };

    programs.zsh.initContent = lib.mkIf cfg.autoStart (
      lib.mkOrder 100 ''
        if [ "$USER" = "${osConfig.mySystem.primaryUser}" ]; then
          export ZELLIJ_AUTO_ATTACH="${if cfg.singleInstance then "true" else "false"}";
          export ZELLIJ_AUTO_EXIT="true";

          eval "$(${lib.getExe config.programs.zellij.package} setup --generate-auto-start zsh)"
        fi
      ''
    );
  };
}
