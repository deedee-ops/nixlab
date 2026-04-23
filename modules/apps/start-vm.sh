# shellcheck shell=bash

set -eu

VM="${1:?usage: $(basename "$0") <vm>}"

_ssh() {
    ssh -F "${XDG_CONFIG_HOME}/ssh/config" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VM" "$@"
}

_spawn() {
    if type disown >/dev/null 2>&1; then
        nohup "${XDG_DATA_HOME}/vms/${VM}/run" >/dev/null 2>&1 </dev/null &
        # shellcheck disable=SC3044
        disown
    else
        (nohup "${XDG_DATA_HOME}/vms/${VM}/run" >/dev/null 2>&1 </dev/null &)
    fi
}

if _ssh true 2>/dev/null; then
    exec ssh -F "${XDG_CONFIG_HOME}/ssh/config" "$VM" 2> /dev/null
fi

echo "No vm '${VM}' detected, booting up..."
_spawn

i=0
while [ "$i" -lt 120 ]; do
    sleep 1
    if _ssh true 2>/dev/null; then
        exec ssh -F "${XDG_CONFIG_HOME}/ssh/config" "$VM" 2> /dev/null
    fi
    i=$((i + 1))
done

echo "Error connecting to the '${VM}' vm" >&2
exit 1
