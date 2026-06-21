# shellcheck shell=bash

set -e
set +o nounset

ci=false
update=false
attic_token=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --ci) ci=true ;;
  --update-flake) update=true ;;
  --attic-token=*) attic_token="${1#*=}" ;;
  --attic-token)
    attic_token="$2"
    shift
    ;;
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

if [[ -n "$attic_token" ]]; then
  attic login homelab https://nix.ajgon.casa "${attic_token}"
fi

# shellcheck disable=SC2044
for host in $(find modules/hosts -maxdepth 1 -mindepth 1 -type d -exec basename {} \;); do
  echo "👷 Building \"${host}\""
  if $ci; then
    nix --accept-flake-config build \
      .#nixosConfigurations."$host".config.system.build.toplevel --out-link "/tmp/result-$host"
  else
    nh os build ".#${host}" --accept-flake-config --out-link "/tmp/result-$host"
  fi

  attic push nixlab "/tmp/result-$host"
done

echo "👷 Building devenv"
devenv shell true >/dev/null 2>&1
attic push nixlab "$(readlink .devenv/profile)"

if $update; then
  echo "👷 Collecting garbage"
  nix-collect-garbage -d
  echo "✅ All done!"
fi
