{ lib, ... }:
{
  options = {
    flake.deploy.nodes = lib.mkOption {
      type = lib.types.attrs;
      description = "A mapper for deploy-rs.";
      default = { };
    };
  };
}
