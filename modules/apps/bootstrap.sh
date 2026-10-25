# shellcheck shell=bash

if (( $# != 1 )) && (( $# != 2 )); then
    >&2 echo "Usage: $0 <machine name> [machine ip]"
    exit 1
fi

MACHINE="$1"

sopsfile="SOPS_${MACHINE}"
if [[ ! -v $sopsfile || -z ${!sopsfile} ]]; then
  echo "'${MACHINE}' is not configured in sops"
  exit 1
fi

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

YAML=$(sops -d "${!sopsfile}")

count=$(echo "$YAML" | yq '.bootstrap | length')

for i in $(seq 0 $((count - 1))); do
  fpath=$(echo "$YAML" | yq ".bootstrap[$i].path")
  content=$(echo "$YAML" | yq ".bootstrap[$i].content")
  mode=$(echo "$YAML" | yq ".bootstrap[$i].mode")

  dest="${temp}/${fpath}"
  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$content" > "$dest"
  chmod "$mode" "$dest"
done

# nixos-anywhere points the installer at the machine's substituters (nix.ajgon.casa), which is signed by the
# homelab CA the stock installer doesn't trust. Kexec first (no-op if the target already runs an installer),
# then make the installer's nix use the target host's own CA bundle, then do the actual install.
cabundle="CA_BUNDLE_${MACHINE}"
nixos-anywhere --phases kexec --no-use-machine-substituters --flake ".#${MACHINE}" "root@${IP}"
# installer host keys are ephemeral, nixos-anywhere doesn't check them either
# shellcheck disable=SC2016 # $HOME must expand on the target
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@${IP}" \
  'mkdir -p "$HOME/.config/nix" && cat > "$HOME/.config/nix/ca-bundle.crt" &&
   echo "ssl-cert-file = $HOME/.config/nix/ca-bundle.crt" >> "$HOME/.config/nix/nix.conf"' <"${!cabundle}"

nixos-anywhere --phases disko,install,reboot --disko-mode disko --extra-files "${temp}" --flake ".#${MACHINE}" "root@${IP}"
