_: {
  flake.homeModules.features-home-zsh =
    { config, lib, ... }:
    let
      cfg = config.features.home.zsh;
    in
    {
      options.features.home.zsh = {
        promptColor = lib.mkOption {
          type = lib.types.str;
          default = "magenta";
          description = "Color of the machine identification box in prompt.";
        };
      };
      config = {
        home = {
          activation = {
            zsh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              run mkdir -p ${config.xdg.stateHome}/zsh || true
            '';
          };
        };

        services =
          lib.genAttrs
            [
              "gpg-agent"
            ]
            (_: {
              enableZshIntegration = true;
            });

        programs =
          (lib.genAttrs
            [
              "atuin"
              "direnv"
              "ghostty"
              "kubecolor"
              "lazygit"
              "nix-index"
              "yazi"
              "zellij"
            ]
            (_: {
              enableZshIntegration = true;
            })
          )
          // {
            kitty.shellIntegration.enableZshIntegration = true;

            zsh = {
              enable = true;

              dotDir = "${config.xdg.configHome}/zsh";

              autosuggestion.enable = true;
              enableCompletion = true;

              sessionVariables.PROMPT_HOSTNAME_COLOR = cfg.promptColor;

              initContent = lib.mkMerge [
                (lib.mkOrder 550 ''
                  autoload -U colors && colors

                  export HISTFILE="${config.xdg.stateHome}/zsh/history"
                '')
              ];

              plugins = lib.mkAfter (
                builtins.map
                  (plugin: {
                    name = "zsh";
                    file = "${plugin}.plugin.zsh";
                    src = ./zsh;
                  })
                  [
                    "keys"
                    "nix"
                    "prompt"
                  ]
              );
            };
          };
      };
    };
}
