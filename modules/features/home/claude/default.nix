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

        home.shellAliases.claude = lib.getExe (
          pkgs.writeShellApplication {
            name = "claude.sh";
            text = ''
              docker pull registry.ajgon.casa/tools/claude
              docker run --rm -it \
                         -v "${config.home.homeDirectory}/Projects/home-ops:/home/ubuntu/home-ops" \
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
