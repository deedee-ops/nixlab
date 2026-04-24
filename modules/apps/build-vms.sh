# shellcheck shell=bash

set -euo pipefail

# shellcheck disable=SC2016
mapfile -t VM_NAMES < <(
    nix eval --raw '.#nixosConfigurations' --apply '
        configs: builtins.concatStringsSep "\n" (
            builtins.filter (name:
                (configs.${name}.config.virtualisation or {}).sharedDirectories or {} != {}
            ) (builtins.attrNames configs)
        )
    '
)

BASE_DIR="${XDG_DATA_HOME:-"${HOME}/.local/share"}/vms"

build_vm() {
    local name="$1"
    local vm_dir="${BASE_DIR}/${name}"
    local storage_dir="${HOME}/Sync/vms/${name}"

    "${vm_dir}/shutdown" || true

    echo "[${name}] Building..."
    mkdir -p "${vm_dir}"

    nix build ".#nixosConfigurations.${name}.config.system.build.vm" \
        -o "${vm_dir}/system"

    cat > "${vm_dir}/run" <<RUNEOF
#!/usr/bin/env bash
mkdir -p "${storage_dir}"

export NIX_DISK_IMAGE="${vm_dir}/${name}.qcow2"
exec "${vm_dir}/system/bin/run-"*"-vm" "\$@"
RUNEOF
    chmod +x "${vm_dir}/run"

    cat > "${vm_dir}/shutdown" <<SHUTEOF
#!/usr/bin/env bash
pkill -TERM -f "${vm_dir}/${name}.qcow2"
SHUTEOF
    chmod +x "${vm_dir}/shutdown"

    echo "[${name}] Done -> ${vm_dir}"
}

pids=()
for name in "${VM_NAMES[@]}"; do
    build_vm "$name" &
    pids+=($!)
done

failed=0
for i in "${!pids[@]}"; do
    wait "${pids[$i]}" || { echo "FAILED: ${VM_NAMES[$i]}"; failed=1; }
done
exit $failed
