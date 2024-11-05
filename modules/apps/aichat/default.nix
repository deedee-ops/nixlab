{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.aichat;
in
{
  options.myHomeApps.aichat = {
    enable = lib.mkEnableOption "aichat";
    apiKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing ChatGPT/OpenAI API key.";
      default = "home/apps/openai/api_key";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.apiKeySopsSecret}" = { };

    home.packages = [
      pkgs.aichat
    ];
    home.shellAliases.ai = "aichat";

    myHomeApps.shellInitScriptContents = [
      ''
        export OPENAI_API_KEY="$(cat ${config.sops.secrets."${cfg.apiKeySopsSecret}".path} | tr -d '\n')"
        _aichat_zsh() {
            if [[ -n "$BUFFER" ]]; then
                local _old=$BUFFER
                BUFFER+="⌛"
                zle -I && zle redisplay
                BUFFER=$(${lib.getExe pkgs.aichat} -e "$_old")
                zle end-of-line
            fi
        }
        zle -N _aichat_zsh
        bindkey '^E' _aichat_zsh
      ''
    ];

    xdg.configFile."aichat/config.yaml".text = ''
      ---
      model: openai
      clients:
        - type: openai
    '';
  };
}
