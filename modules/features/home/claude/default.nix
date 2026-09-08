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
        extraArgs = lib.mkOption {
          type = lib.types.str;
          description = "List of extra arguments passed to docker runner";
          default = "";
          example = "--network=host";
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
                CFGDIR="$(mktemp -d)"
                cleanup() {
                    [[ -n "$CFGDIR" ]] && rm -rf -- "$CFGDIR"
                }

                trap cleanup EXIT HUP INT TERM
                mkdir -p "$CFGDIR/kube" "$CFGDIR/talos"
                cp -a "${config.sops.secrets."features/home/claude/configs/kubeconfig".path}" "$CFGDIR/kube/config"
                cp -a "${
                  config.sops.secrets."features/home/claude/configs/talosconfig".path
                }" "$CFGDIR/talos/config"
                chmod 600 "$CFGDIR/kube/config"
                chmod 600 "$CFGDIR/talos/config"

                docker pull registry.ajgon.casa/tools/claude
                docker run --rm -it \
                           ${extraMounts} ${defaultContext} ${cfg.extraArgs} \
                           -v "${config.xdg.configHome}/claude:/home/ubuntu/.config/claude" \
                           -v "$(pwd):$(pwd)" \
                           -v "$CFGDIR/kube:/home/ubuntu/.config/kube" \
                           -v "$CFGDIR/talos:/home/ubuntu/.config/talos" \
                           -w "$(pwd)" \
                           registry.ajgon.casa/tools/claude "$@"
              '';
            }
          );
      };
    };
}
