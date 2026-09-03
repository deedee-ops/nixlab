_: {
  flake.homeModules.features-home-claude =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.home.claude;
    in
    {
      options.features.home.claude = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
        defaultContext = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "You are claude, do claude stuff";
        };
        extraMounts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of extra directories to be mounted";
          default = [ ];
          example = "/home/example/dir:/dir";
        };
      };
      config = {
        sops.secrets = {
          "features/home/claude/configs/kubeconfig" = {
            sopsFile = cfg.sopsSecretsFile;
          };
          "features/home/claude/configs/talosconfig" = {
            sopsFile = cfg.sopsSecretsFile;
          };
        };

        home.shellAliases.claude =
          let
            extraMounts =
              if builtins.length cfg.extraMounts > 0 then
                "-v ${builtins.concatStringsSep " -v " cfg.extraMounts}"
              else
                "";
            defaultContext =
              if cfg.defaultContext != null then
                "-v ${pkgs.writeText "CLAUDE.md" cfg.defaultContext}:/home/ubuntu/CLAUDE.md:ro"
              else
                "";
          in
          lib.getExe (
            pkgs.writeShellApplication {
              name = "claude.sh";
              text = ''
                docker pull registry.ajgon.casa/tools/claude
                docker run --rm -it \
                           ${extraMounts} ${defaultContext} \
                           -v "${config.xdg.configHome}/claude:/home/ubuntu/.config/claude" \
                           -v "$(pwd):$(pwd)" \
                           -v "${
                             config.sops.secrets."features/home/claude/configs/kubeconfig".path
                           }:/home/ubuntu/.config/kube/config" \
                           -v "${
                             config.sops.secrets."features/home/claude/configs/talosconfig".path
                           }:/home/ubuntu/.config/talos/config" \
                           -w "$(pwd)" \
                           registry.ajgon.casa/tools/claude "$@"
              '';
            }
          );
      };
    };
}
