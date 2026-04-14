_: {
  flake.homeModules.features-home =
    { pkgs, lib, ... }:
    {
      config = {
        xdg.enable = true;
        home.preferXdgDirectories = true;

        home.shellAliases = {
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
}
