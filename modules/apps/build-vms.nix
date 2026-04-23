_: {
  perSystem =
    { pkgs, ... }:
    {
      apps.build-vms = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "build-vms";
          text = builtins.readFile ./build-vms.sh;
        };
      };
    };
}
