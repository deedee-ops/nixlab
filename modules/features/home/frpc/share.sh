# shellcheck shell=bash

# Serves files straight from this machine through frps until Ctrl-C, -t or
# (with -1) the first complete download.
# Prelude (default.nix) sets FRPC_SERVER_ADDR, FRPC_SERVER_PORT, FRPC_CA_FILE,
# FRPC_TOKEN_FILE, SHARE_DOMAIN and SHARE_SERVER.

usage() {
  echo "usage: share [-1] [-t DURATION] <path>..." >&2
  echo "  -1           stop after the first complete download" >&2
  echo "  -t DURATION  stop sharing after DURATION (timeout(1) syntax, e.g. 30m, 2h)" >&2
  exit 1
}

duration=""
once=""
while getopts ":1t:h" opt; do
  case "$opt" in
  1) once="--once" ;;
  t) duration="$OPTARG" ;;
  *) usage ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || usage

workdir="$(mktemp -d)"
pids=()
cleanup() {
  if [[ ${#pids[@]} -gt 0 ]]; then
    kill "${pids[@]}" 2>/dev/null || true
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

# Lets the readiness check below fetch a link without it being reported.
SHARE_PROBE_TOKEN="$(head -c 16 /dev/urandom | basenc --base64url)"
export SHARE_PROBE_TOKEN

python3 "$SHARE_SERVER" --root "$workdir/root" --id "$id" --port-file "$workdir/port" ${once:+"$once"} &
pids+=($!)
for _ in $(seq 1 50); do
  [[ -s "$workdir/port" ]] && break
  sleep 0.1
done
if [[ ! -s "$workdir/port" ]]; then
  echo "share: file server did not start" >&2
  exit 1
fi

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
localIP = "127.0.0.1"
localPort = $(<"$workdir/port")
TOML

FRP_AUTH_TOKEN="$(<"$FRPC_TOKEN_FILE")"
export FRP_AUTH_TOKEN

if [[ -n "$duration" ]]; then
  timeout "$duration" frpc -c "$workdir/frpc.toml" &
else
  frpc -c "$workdir/frpc.toml" &
fi
pids+=($!)

# Print the links only once the first one answers from the outside.
probe() {
  curl -fs -r 0-0 -o /dev/null -H "X-Share-Probe: $SHARE_PROBE_TOKEN" "${links[0]}"
}
for _ in $(seq 1 30); do
  kill -0 "${pids[@]}" 2>/dev/null || {
    echo "share: frpc exited" >&2
    exit 1
  }
  probe && break
  sleep 0.5
done
if ! probe; then
  echo "share: ${links[0]} is not reachable" >&2
  exit 1
fi

printf '%s\n' "${links[@]}"
if command -v wl-copy >/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  printf '%s\n' "${links[@]}" | wl-copy
  echo "(copied to clipboard)" >&2
fi
echo "sharing${duration:+ for $duration}${once:+ until the first complete download}, Ctrl-C to stop" >&2

# Whichever ends first (timeout, -1, a crash) ends the share.
wait -n "${pids[@]}" || true
