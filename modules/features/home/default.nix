_: {
  flake.homeModules.features-home =
    { pkgs, lib, ... }:
    {
      options = {
        systemTheme = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Theme name";
                example = "catppuccin";
              };
              style = lib.mkOption {
                type = lib.types.str;
                description = "Theme style";
                example = "mocha";
              };
            };
          };
        };
      };
      config = {
        xdg.enable = true;
        home = {
          preferXdgDirectories = true;

          packages = [
            pkgs.silver-searcher
            pkgs.xterm
            pkgs.alacritty
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
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            # check sync process (usually when unmounting USBs)
            syncstatus = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
          };
        };
      };
    };
}
