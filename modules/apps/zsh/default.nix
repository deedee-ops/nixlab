{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.zsh;
  shellInitExtra =
    (builtins.concatStringsSep "\n" (
      builtins.map (f: builtins.readFile f) config.myHomeApps.shellInitScriptFiles
    ))
    + "\n"
    + config.myHomeApps.shellInitScriptContents;

  myFunctions = pkgs.stdenvNoCC.mkDerivation rec {
    name = "zsh-functions-${version}";
    version = "0.0.1";
    src = ./functions;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir $out

      cp $src/* $out/
    '';
  };
in
{
  options.myHomeApps.zsh = {
    enable = lib.mkEnableOption "zsh" // {
      default = true;
    };
    promptColor = lib.mkOption {
      type = lib.types.str;
      default = "magenta";
      description = "Color of the machine identification box in prompt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      activation = {
        zsh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.xdg.stateHome}/zsh || true
        '';
      };
    };

    programs.zsh = {
      enable = true;

      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = true;

      autosuggestion = {
        enable = true;
      };

      sessionVariables.PROMPT_HOSTNAME_COLOR = cfg.promptColor;

      completionInit = "autoload -U compinit && compinit -u -d \"${config.xdg.cacheHome}/zsh/.compdump-$USER\"";

      initContent = lib.mkMerge [
        (lib.mkOrder 550 ''
          autoload -U colors && colors
        '')

        (
          ''
            export HISTFILE="${config.xdg.stateHome}/zsh/history"
          ''
          + (lib.optionalString config.myHomeApps.ghostty.enable ''

            if [[ "$TERM" == "xterm-ghostty" ]]; then
              source ${pkgs.ghostty.shell_integration}/zsh/ghostty-integration
            fi
          '')
          + ''

            ${shellInitExtra}
          ''
        )
      ];

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "......" = "cd ../../../../..";
        "......." = "cd ../../../../../..";
        "........" = "cd ../../../../../../..";

        grep = "grep --color";
        ls = "ls --color";

        # check sync process (usually when unmounting USBs)
        syncstatus = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
        pbcopy = "xclip -selection clipboard";
        pbpaste = "xclip -selection clipboard -o";
      };

      plugins = [
        {
          name = "functions";
          src = myFunctions;
        }
      ];
    };
  };
}
