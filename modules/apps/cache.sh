# shellcheck shell=bash

set -e
set +o nounset

ci=false
update=false

# ncps exposes its write routes under /upload and re-signs what it stores with its
# own key, so pushing needs no credentials -- it is gated on the server by
# --cache-allow-put-verb and kept off the public router. zstd is set explicitly
# because nix would otherwise default to xz, which is far slower for no gain here.
cache_url="https://nix.ajgon.casa/upload?compression=zstd"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --ci) ci=true ;;
  --update-flake) update=true ;;
  --github-token=*) github_token="${1#*=}" ;;
  --github-token)
    github_token="$2"
    shift
    ;;
  esac
  shift
done

if $ci; then
  if [[ -n "${NIX_SSL_CERT_FILE}" ]]; then
    cat assets/ca-ec384.crt >>"${NIX_SSL_CERT_FILE}"
    cat assets/ca-rsa4096.crt >>"${NIX_SSL_CERT_FILE}"
  fi

  mkdir -p ~/.config/nix
  if [[ -n "$github_token" ]]; then
    echo "access-tokens = github.com=${github_token}" >>~/.config/nix/nix.conf
  fi

  nix eval --json --impure --expr "(import \"$(pwd)/flake.nix\").nixConfig" |
    jq -r 'to_entries[] | "\(.key) = \(if (.value | type) == "array" then (.value | join(" ")) else .value end)"' \
      >>~/.config/nix/nix.conf
fi

if $update; then
  echo "👷 Updating flake"
  nix --accept-flake-config flake update
  echo "✅ All done!"
  echo "👷 Updating devenv"
  devenv update
  echo "✅ All done!"
fi

# `nix copy` below pushes each host's *runtime* closure, which does not reference
# the flake inputs -- so nixpkgs, home-manager, disko et al never reach the cache
# that way, and without them the flake cannot even be evaluated offline. Archive
# them explicitly, and do it here rather than at the end: the `nix-collect-garbage
# -d` below can drop input source trees, since they are not strongly GC-rooted.
echo "👷 Archiving flake inputs"
nix --accept-flake-config flake archive --to "$cache_url"
echo "✅ All done!"

# shellcheck disable=SC2044
for host in $(find modules/hosts -maxdepth 1 -mindepth 1 -type d -exec basename {} \;); do
  echo "👷 Building \"${host}\""
  if $ci; then
    nix --accept-flake-config build \
      .#nixosConfigurations."$host".config.system.build.toplevel --out-link "/tmp/result-$host"
  else
    nh os build ".#${host}" --accept-flake-config --out-link "/tmp/result-$host"
  fi

  nix copy --to "$cache_url" "/tmp/result-$host"
done

echo "👷 Building devenv"
devenv shell true >/dev/null 2>&1
nix copy --to "$cache_url" "$(readlink .devenv/profile)"

if $update; then
  echo "👷 Collecting garbage"
  nix-collect-garbage -d
  echo "✅ All done!"
fi
