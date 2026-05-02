{ self, ... }:
{
  flake.homeModules = {
    features-home =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        config =
          let
            startVMpkg = pkgs.writeShellApplication {
              name = "start-vm";
              runtimeInputs = [
                pkgs.openssh
              ];
              text = builtins.readFile ../../apps/start-vm.sh;
            };
          in
          {
            xdg.enable = true;
            home = {
              preferXdgDirectories = true;
              activation.init-paths = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                ln -s ${config.home.homeDirectory}/Sync/sync/claude/ ${config.xdg.configHome}/claude || true
              '';

              packages = [
                pkgs.silver-searcher
                pkgs.wget
                pkgs.xterm
              ];

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

                claude = ''docker run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude'';
                claude-chat = ''docker run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -w /var/empty ghcr.io/ajgon/claude'';
                claude-go = ''docker run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude-go'';
                claude-node = ''docker run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/node/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude-node'';

                w = "${lib.getExe startVMpkg} work";
              }
              // lib.optionalAttrs pkgs.stdenv.isLinux {
                # check sync process (usually when unmounting USBs)
                syncstatus = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
              };
            };
          };
      };

    features-home-console = _: {
      imports = [
        self.homeModules.features-home-atuin
        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-direnv
        self.homeModules.features-home-git
        self.homeModules.features-home-gnupg
        self.homeModules.features-home-kubernetes
        self.homeModules.features-home-neovim
        self.homeModules.features-home-shell
        self.homeModules.features-home-ssh
        self.homeModules.features-home-wakatime
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zsh
      ];
    };

    features-home-gui = _: {
      imports = [
        self.homeModules.features-home-discord
        self.homeModules.features-home-firefox
        self.homeModules.features-home-keepassxc
        self.homeModules.features-home-kitty
        self.homeModules.features-home-niri
        self.homeModules.features-home-noctalia-shell
        self.homeModules.features-home-obsidian
        self.homeModules.features-home-rustdesk
        self.homeModules.features-home-supersonic
        self.homeModules.features-home-syncthing
        self.homeModules.features-home-teams
        self.homeModules.features-home-telegram
        self.homeModules.features-home-thunderbird
        self.homeModules.features-home-vicinae
        self.homeModules.features-home-wayland
        self.homeModules.features-home-zathura
      ];
    };
  };
}
