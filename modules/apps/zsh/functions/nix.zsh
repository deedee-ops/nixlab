function ns() {
  cmd="nix shell"
  for pkg in "$@"; do
    cmd="${cmd} nixpkgs#${pkg} --impure"
  done

  eval "$cmd"
}
