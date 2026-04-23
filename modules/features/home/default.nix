_: {
  flake.homeModules.features-home =
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

              claude = ''${lib.getExe pkgs.docker} run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude'';
              claude-chat = ''${lib.getExe pkgs.docker} run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -w /var/empty ghcr.io/ajgon/claude'';
              claude-go = ''${lib.getExe pkgs.docker} run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/ubuntu/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude-go'';
              claude-node = ''${lib.getExe pkgs.docker} run --rm -it -v "$XDG_CONFIG_HOME/claude":/home/node/.config/claude -v "$(pwd):/work" -w /work ghcr.io/ajgon/claude-node'';

              w = "${lib.getExe startVMpkg} work";
            }
            // lib.optionalAttrs pkgs.stdenv.isLinux {
              # check sync process (usually when unmounting USBs)
              syncstatus = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
            };
          };
        };
    };
}
