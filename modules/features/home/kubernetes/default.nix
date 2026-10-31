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
      krewCfg = config.programs.krewfile;
      krewfileSync = pkgs.writeShellScript "krewfile-sync" ''
        set -e
        export KREW_ROOT="${krewCfg.krewRoot}"
        export PATH="$KREW_ROOT/bin:${lib.makeBinPath [ pkgs.git ]}:$PATH"
        ${lib.getExe pkgs.krew} update
        ${lib.getExe' inputs.krewfile.packages.${pkgs.stdenv.hostPlatform.system}.default "krewfile"} \
          -command ${lib.getExe pkgs.krew} -file ${
            pkgs.writeText "krewfile" (
              lib.concatStringsSep "\n" (lib.mapAttrsToList (name: url: "index ${name} ${url}") krewCfg.indexes)
              + "\n\n"
              + lib.concatStringsSep "\n" krewCfg.plugins
            )
          } ${lib.optionalString krewCfg.upgrade "-upgrade"}
      '';
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
          mode = "0600";
        });

        programs.noctalia.settings.theme.templates.community_ids = [ "fzf" ];
        stylix.targets = {
          k9s.enable = true;
          kubecolor.enable = true;
        };

        home = {
          packages = [
            pkgs.fzf # for kubectl ctx
            pkgs.kubectl
            pkgs.stern
          ];

          # plugin sync needs the network, so it runs from the krewfile units below instead
          activation.krew = lib.mkForce (lib.hm.dag.entryAfter [ "installPackages" ] "");

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
            plugins = [
              {
                name = "kubernetes";
                src = ./zsh;
              }
            ];
          };
        };

        systemd.user = {
          services = {
            krewfile = {
              Unit = {
                Description = "Sync krew indexes and plugins with the krewfile";
                StartLimitIntervalSec = 3600;
                StartLimitBurst = 5;
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${krewfileSync}";
                Restart = "on-failure";
                RestartSec = 300;
              };
            };
            init-kubeconfig = lib.mkHomeActivationAfterSops {
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
            # first install only, afterwards the weekly timer keeps plugins current
            krewfile-init = {
              Unit = {
                Description = "Install krew plugins from the krewfile";
                ConditionPathExists = "!${krewCfg.krewRoot}/receipts";
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${krewfileSync}";
              };
              Install.WantedBy = [ "default.target" ];
            };
          };
          timers.krewfile = {
            Timer = {
              OnCalendar = "weekly";
              Persistent = true;
              RandomizedDelaySec = 3600;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        };
      };
    };
}
