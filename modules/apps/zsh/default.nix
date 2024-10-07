{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myApps.zsh;
  shellInitExtra =
    (builtins.concatStringsSep "\n" (
      builtins.map (f: builtins.readFile f) config.myApps.shellInitScriptFiles
    ))
    + "\n"
    + (builtins.concatStringsSep "\n" config.myApps.shellInitScriptContents);

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
  options.myApps.zsh = {
    enable = lib.mkEnableEnabledOption "zsh";
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

      dotDir = ".config/zsh";
      enableCompletion = true;

      autosuggestion = {
        enable = true;
      };

      sessionVariables.PROMPT_HOSTNAME_COLOR = cfg.promptColor;

      completionInit = "autoload -U compinit && compinit -u";

      initExtraBeforeCompInit = ''
        autoload -U colors && colors
      '';

      initExtra = ''
        export HISTFILE="${config.xdg.stateHome}/zsh/history"

        ${shellInitExtra}
      '';

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

        # sudo - pass env
        sudo = "sudo -E";

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
