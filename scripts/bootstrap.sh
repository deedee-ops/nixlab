
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

nixos-anywhere --disko-mode disko --extra-files "${temp}" --flake ".#${MACHINE}" "root@${IP}"
