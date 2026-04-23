{ inputs, ... }:
{
  flake.homeModules.features-home-kubernetes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.home.kubernetes;
    in
    {
      options.features.home.kubernetes = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };

      config = {
        sops.secrets = lib.genAttrs [ "features/home/kubernetes/kubeconfig" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
        });

        stylix.targets = {
          k9s.enable = true;
          kubecolor.enable = true;
        };

        home = {
          packages = [
            pkgs.kubectl
            pkgs.stern
          ];

          activation =
            let
              cfg = config.programs.krewfile;
              krewfilePkg = inputs.krewfile.packages."${pkgs.stdenv.hostPlatform.system}".default;
              krewfileContent = pkgs.writeText "krewfile" (
                (builtins.concatStringsSep "\n" (
                  map (key: "index ${key} ${builtins.getAttr key cfg.indexes}") (builtins.attrNames cfg.indexes)
                ))
                + "\n\n"
                + (builtins.concatStringsSep "\n" cfg.plugins)
              );
              args = if cfg.upgrade then "-upgrade" else "";
            in
            {
              krew = lib.mkForce (
                lib.hm.dag.entryAfter [ "installPackages" ] ''
                  export KREW_ROOT="${config.xdg.configHome}/krew";
                  export PATH="$KREW_ROOT/bin:$PATH"
                  run ${lib.getExe' krewfilePkg "krewfile"} -command ${lib.getExe pkgs.krew} -file ${krewfileContent} ${args} || true
                  run ${pkgs.krew}/bin/krew update || true
                ''
              );
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
              "default" = "https://github.com/kubernetes-sigs/krew-index.git";
              "netshoot" = "https://github.com/nilic/kubectl-netshoot.git";
            };
            plugins = [
              "netshoot/netshoot"
              "ctx"
              "modify-secret"
              "node-shell"
              "ns"
              "oidc-login"
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

          zsh = {
            initContent = lib.mkOrder 1000 ''
              source <(${lib.getExe pkgs.kubectl} completion zsh)
            '';
            plugins = [
              {
                name = "kubernetes";
                src = ./zsh;
              }
            ];
          };
        };

        systemd.user.services.init-kubeconfig = lib.mkHomeActivationAfterSops {
          name = "init-kubeconfig";
          script = ''
            # kubens and kubectx write lock files alongside config, so using kubeconfig directly from secrets path won't work
            # it also can't be symlinked, because sops-nix daemon periodically restores it

            mkdir -p "${config.xdg.configHome}/kube"
            rm -rf "${config.xdg.configHome}/kube/config" || true
            cp "${
              config.sops.secrets."features/home/kubernetes/kubeconfig".path
            }" "${config.xdg.configHome}/kube/config"
          '';
        };
      };
    };
}
