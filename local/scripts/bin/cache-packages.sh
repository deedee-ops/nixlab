#!/usr/bin/env bash

for sub in $(nix --accept-flake-config eval --json '.#nixlab.nixConfig.substituters' | jq -r '.[]' | grep -v 'cache.nixos.org'); do
  s3sub="$(echo "$sub" | sed -E 's@^([^:]+)://([^/]+)/([^?]+)\??(.*)$@s3://\3?endpoint=\2\&scheme=\1\&\4\&compression=zstd@g')"
  for machine in $(nix --accept-flake-config flake show --json 2> /dev/null | jq -r '.nixosConfigurations | keys | .[]'); do
    drv=".#nixosConfigurations.$machine.config.system.build.toplevel"

    printf "\033[1;91mBuilding and caching %s...\033[0m\n" "${machine}"

    if [ -n "$CI" ]; then
      nix build --accept-flake-config --fallback --no-link "$drv"
    else
      nom build --accept-flake-config --fallback --no-link "$drv"
    fi
    nix --accept-flake-config store sign --key-file <(echo "${NIXCACHE_PRIVATE_KEY}") --recursive "$drv"
    nix --accept-flake-config store verify --sigs-needed 1 --recursive "$drv" --option trusted-public-keys "${NIXCACHE_PUBLIC_KEY}"
    nix --accept-flake-config --refresh copy --to "$s3sub" "$drv"
  done

  drv=".#devShells.x86_64-linux.default"
  printf "\033[1;91mBuilding and caching devshell...\033[0m\n"
  if [ -n "$CI" ]; then
    nix build --accept-flake-config --fallback --no-link "$drv"
  else
    nom build --accept-flake-config --fallback --no-link "$drv"
  fi
  nix --accept-flake-config store sign --key-file <(echo "${NIXCACHE_PRIVATE_KEY}") --recursive "$drv"
  nix --accept-flake-config store verify --sigs-needed 1 --recursive "$drv" --option trusted-public-keys "${NIXCACHE_PUBLIC_KEY}"
  nix --accept-flake-config --refresh copy --to "$s3sub" "$drv"
done
