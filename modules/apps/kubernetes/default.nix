{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.kubernetes;
in
{
  options.myHomeApps.kubernetes = {
    enable = lib.mkEnableOption "kubernetes apps";
    kubeconfigSopsSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Sops secret name containing kubeconfig.";
      default = null; # "home/apps/kubernetes/kubeconfig";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mkIf (cfg.kubeconfigSopsSecret != null) {
      "${cfg.kubeconfigSopsSecret}" = {
        mode = "0600";
      };
    };

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
        // lib.optionalAttrs (cfg.kubeconfigSopsSecret != null) {
          # kubens and kubectx write lock files alongside config, so using kubeconfig directly from secrets path won't work
          init-kubeconfig = lib.hm.dag.entryAfter [ "sopsNix" ] ''
            run ln -sf "${
              config.sops.secrets."${cfg.kubeconfigSopsSecret}".path
            }" "${config.xdg.configHome}/kube/config"
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
        enableAlias = true;
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
}
