function ns() {
  export NIXPKGS_ALLOW_UNFREE=1
  cmd="nix shell"
  for pkg in "$@"; do
    cmd="${cmd} nixpkgs#${pkg} --impure"
  done

  eval "$cmd"
}
