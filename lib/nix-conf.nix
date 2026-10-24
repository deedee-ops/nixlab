let
  settings = import ../nix-settings.nix;
  render =
    value: if builtins.isBool value then (if value then "true" else "false") else toString value;
in
builtins.concatStringsSep "" (
  map (name: "${name} = ${render settings.${name}}\n") (builtins.attrNames settings)
)
