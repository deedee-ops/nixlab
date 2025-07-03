#!/usr/bin/env bash

for sub in $(nix --accept-flake-config eval --json '.#nixlab.nixConfig.substituters' | jq -r '.[]' | grep -v 'cache.nixos.org'); do
  s3sub="$(echo "$sub" | sed -E 's@^([^:]+)://([^/]+)/([^?]+)\??(.*)$@s3://\3?endpoint=\2\&scheme=\1\&\4@g')"
  for machine in $(nix --accept-flake-config flake show --json 2> /dev/null | jq -r '.nixosConfigurations | keys | .[]'); do
    drv=".#nixosConfigurations.$machine.config.system.build.toplevel"

    nom build --accept-flake-config --fallback --no-link "$drv"
    nix --accept-flake-config store sign --key-file <(echo "${NIXCACHE_PRIVATE_KEY}") --recursive "$drv"
    nix --accept-flake-config store verify --sigs-needed 1 --recursive "$drv" --option trusted-public-keys "${NIXCACHE_PUBLIC_KEY}"
    nix --accept-flake-config --refresh copy --to "$s3sub" "$drv"
  done

  drv=".#devShells.x86_64-linux.default"
  nom build --accept-flake-config --fallback --no-link "$drv"
  nix --accept-flake-config store sign --key-file <(echo "${NIXCACHE_PRIVATE_KEY}") --recursive "$drv"
  nix --accept-flake-config store verify --sigs-needed 1 --recursive "$drv" --option trusted-public-keys "${NIXCACHE_PUBLIC_KEY}"
  nix --accept-flake-config --refresh copy --to "$s3sub" "$drv"
done
