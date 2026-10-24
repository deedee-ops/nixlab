# shellcheck shell=bash

# Serves files straight from this machine through frps until Ctrl-C (or -t).
# Prelude (default.nix) sets FRPC_SERVER_ADDR, FRPC_SERVER_PORT, FRPC_CA_FILE,
# FRPC_TOKEN_FILE and SHARE_DOMAIN.

usage() {
  echo "usage: share [-t DURATION] <path>..." >&2
  echo "  -t DURATION  stop sharing after DURATION (timeout(1) syntax, e.g. 30m, 2h)" >&2
  exit 1
}

duration=""
while getopts ":t:h" opt; do
  case "$opt" in
  t) duration="$OPTARG" ;;
  *) usage ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || usage

workdir="$(mktemp -d)"
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -rf -- "$workdir"
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

# Only symlinks to the shared paths live in the served root, so nothing else
# on disk is reachable.
id="$(head -c 16 /dev/urandom | basenc --base64url | tr -d '=')"
mkdir "$workdir/root"
links=()
for path in "$@"; do
  if [[ ! -e "$path" ]]; then
    echo "share: $path: no such file or directory" >&2
    exit 1
  fi
  target="$(realpath -- "$path")"
  name="$(basename -- "$target")"
  if [[ -e "$workdir/root/$name" ]]; then
    echo "share: $name given twice" >&2
    exit 1
  fi
  ln -s -- "$target" "$workdir/root/$name"
  suffix=""
  [[ -d "$target" ]] && suffix="/"
  links+=("https://${SHARE_DOMAIN}/${id}/$(jq -rn --arg n "$name" '$n | @uri')${suffix}")
done

cat >"$workdir/frpc.toml" <<TOML
serverAddr = "${FRPC_SERVER_ADDR}"
serverPort = ${FRPC_SERVER_PORT}
loginFailExit = true

auth.method = "token"
auth.token = "{{ .Envs.FRP_AUTH_TOKEN }}"

transport.tls.serverName = "${FRPC_SERVER_ADDR}"
transport.tls.trustedCaFile = "${FRPC_CA_FILE}"

log.level = "warn"

[[proxies]]
name = "share-${id}"
type = "http"
customDomains = ["${SHARE_DOMAIN}"]
locations = ["/${id}"]

[proxies.plugin]
type = "static_file"
localPath = "$workdir/root"
stripPrefix = "${id}"
TOML

FRP_AUTH_TOKEN="$(<"$FRPC_TOKEN_FILE")"
export FRP_AUTH_TOKEN

if [[ -n "$duration" ]]; then
  timeout "$duration" frpc -c "$workdir/frpc.toml" &
else
  frpc -c "$workdir/frpc.toml" &
fi
pid=$!

# Print the links only once the first one answers from the outside (the
# static_file plugin serves GET only, so probe with a 1-byte range).
for _ in $(seq 1 30); do
  kill -0 "$pid" 2>/dev/null || {
    echo "share: frpc exited" >&2
    exit 1
  }
  curl -fs -r 0-0 -o /dev/null "${links[0]}" && break
  sleep 0.5
done
if ! curl -fs -r 0-0 -o /dev/null "${links[0]}"; then
  echo "share: ${links[0]} is not reachable" >&2
  exit 1
fi

printf '%s\n' "${links[@]}"
if command -v wl-copy >/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  printf '%s\n' "${links[@]}" | wl-copy
  echo "(copied to clipboard)" >&2
fi
echo "sharing${duration:+ for $duration}, Ctrl-C to stop" >&2

wait "$pid" || true
