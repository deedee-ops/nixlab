{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myApps.kubernetes;
in
{
  options.myApps.kubernetes = {
    enable = lib.mkEnableOption "kubernetes apps";
    kubeconfigPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to kubeconfig file. It will be symlinked to ~/.config/kube/config.";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.k9s.enable = true;
    stylix.targets.kubecolor.enable = true;

    home = {
      packages = [
        pkgs.kubectl
        pkgs.stern
      ];

      activation =
        {
          init-krew = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            export KREW_ROOT="${config.xdg.configHome}/krew";
            run ${pkgs.krew}/bin/krew update
          '';
        }
        // lib.optionalAttrs (cfg.kubeconfigPath != null) {
          # kubens and kubectx write lock files alongside config, so using kubeconfig directly from secrets path won't work
          init-kubeconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ln -s "${cfg.kubeconfigPath}" "${config.xdg.configHome}/kube/config" || true
          '';

        };

      sessionVariables = {
        KREW_ROOT = "${config.xdg.configHome}/krew";
        KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
        KUBECONFIG = "${config.xdg.configHome}/kube/config";
      };

      shellAliases = {
        k = "kubectl";
      };
    };

    programs = {
      kubecolor = {
        enable = true;
        overrideKubectl = true;
      };

      krewfile = {
        enable = true;
        krewPackage = pkgs.krew;
        krewRoot = "${config.xdg.configHome}/krew";
        upgrade = true;
        indexes = {
          "netshoot" = "https://github.com/nilic/kubectl-netshoot.git";
        };
        plugins = [
          "netshoot/netshoot"
          "ctx"
          "modify-secret"
          "node-shell"
          "ns"
          "popeye"
          "resource-capacity"
        ];
      };

      k9s = {
        enable = true;
        plugin = {
          plugins = {
            edit-secret = {
              shortCut = "Shift-E";
              confirm = false;
              description = "Edit Decoded Secret";
              scopes = [ "secrets" ];
              command = "${pkgs.kubectl}/bin/kubectl";
              background = false;
              args = [
                "modify-secret"
                "--namespace"
                "$NAMESPACE"
                "--context"
                "$CONTEXT"
                "$NAME"
              ];
            };
          };
        };
      };
    };
  };
}
