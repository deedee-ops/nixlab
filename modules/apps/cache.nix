_: {
  perSystem =
    { pkgs, ... }:
    {
      apps.cache = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "cache";
          runtimeInputs = [
            pkgs.devenv
            pkgs.git
            pkgs.nh
          ];
          text = ''
            ${builtins.readFile ./cache.sh}
          '';
        };
      };
    };
}
