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
            pkgs.jq
            pkgs.nh
          ];
          text = ''
            ${builtins.readFile ./cache.sh}
          '';
        };
      };
    };
}
