_: {
  flake.homeModules.features-home-ssh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        sops.secrets = lib.genAttrs [ "ssh/privateKey" ] (_: {
          sopsFile = ./secrets.sops.yaml;
        });

        programs = {
          ssh = {
            enable = true;
            enableDefaultConfig = false;
            package = pkgs.symlinkJoin {
              name = "ssh";
              paths = [
                (pkgs.writeShellScriptBin "ssh" ''
                  exec ${lib.getExe pkgs.openssh} -F ${config.xdg.configHome}/ssh/config "$@"
                '')
                (pkgs.writeShellScriptBin "scp" ''
                  exec ${lib.getExe' pkgs.openssh "scp"} -F ${config.xdg.configHome}/ssh/config "$@"
                '')
                (pkgs.writeShellScriptBin "sftp" ''
                  exec ${lib.getExe' pkgs.openssh "sftp"} -F ${config.xdg.configHome}/ssh/config "$@"
                '')
                (pkgs.writeShellScriptBin "ssh-copy-id" ''
                  exec ${lib.getExe' pkgs.openssh "ssh-copy-id"} -F ${config.xdg.configHome}/ssh/config "$@"
                '')
                pkgs.openssh
              ];
            };

            matchBlocks = {
              "*" = {
                addKeysToAgent = "8h";
                controlPath = "${config.xdg.stateHome}/ssh/master-%r@%n:%p";
                userKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
              };
              # private
              forgejo = {
                forwardAgent = false;
                host = "git.ajgon.casa";
                hostname = "git.ajgon.casa";
                identitiesOnly = true;
                identityFile = [ config.sops.secrets."ssh/privateKey".path ];
                port = 22;
                user = "git";
              };
              mandark = {
                forwardAgent = true;
                host = "mandark";
                hostname = "relay.rzegocki.dev";
                identitiesOnly = true;
                identityFile = [ config.sops.secrets."ssh/privateKey".path ];
                port = 22;
                user = "ajgon";
              };
              nas = {
                forwardAgent = false;
                host = "nas";
                hostname = "nas.internal";
                identitiesOnly = true;
                identityFile = [ config.sops.secrets."ssh/privateKey".path ];
                port = 22;
                user = "ajgon";
              };

              # public
              github = {
                forwardAgent = false;
                host = "github.com";
                hostname = "github.com";
                identitiesOnly = true;
                identityFile = [ config.sops.secrets."ssh/privateKey".path ];
                port = 22;
                user = "git";
              };

            };
          };
        };

        services.ssh-agent = {
          enable = true;
        };

        home = {
          activation = {
            ssh-state = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              run mkdir -p ${config.xdg.stateHome}/ssh || true
            '';
          };
        };

        # hack to move ssh config from ~/.ssh/config to ~/.config/ssh/config
        home.file.".ssh/config".enable = false;
        xdg.configFile."ssh/config".text = config.home.file.".ssh/config".text;
      };
    };
}
