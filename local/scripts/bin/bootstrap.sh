#!/usr/bin/env bash

if (( $# != 1 )) && (( $# != 2 )); then
    >&2 echo "Usage: $0 <machine name> [machine ip]"
    exit 1
fi

# shellcheck disable=SC2164
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MACHINE="$1"

if (( $# != 2 )); then
  IP="$(nix eval --raw ".#deploy.nodes.${MACHINE}.hostname")"
else
  IP="$2"
fi

temp=$(mktemp -d)

cleanup() {
  rm -rf "${temp}"
}
trap cleanup EXIT

openssl aes-256-cbc -d -a -salt -md sha256 -pbkdf2 -in "${SCRIPTPATH}/../secrets.tar.gz.enc" | tar -xz -C "${temp}"

nixos-anywhere --disko-mode disko --extra-files "${temp}/${MACHINE}" --flake ".#${MACHINE}" "root@${IP}"
