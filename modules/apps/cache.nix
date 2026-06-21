_: {
  perSystem =
    { pkgs, ... }:
    {
      apps.cache = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "cache";
          runtimeInputs = [
            pkgs.attic-client
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
