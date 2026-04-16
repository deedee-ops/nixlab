# shellcheck shell=bash
#
# Usage: niri-switch-ws <number> [--move]
# Switches to workspace N on the currently focused monitor.
# With --move, moves the focused window there.

NUM="$1"
ACTION="${2:-"--switch"}"

# Get the focused output name
FOCUSED_OUTPUT=$(niri msg --json focused-output | jq -r '.name')
WS_NAME="${NUM}-${FOCUSED_OUTPUT}"

if [ "$ACTION" = "--move" ]; then
    niri msg action move-window-to-workspace "$WS_NAME"
else
    niri msg action focus-workspace "$WS_NAME"
fi
