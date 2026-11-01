# shellcheck shell=bash

# Switch Bluetooth headsets between music (A2DP) and call (HSP/HFP) profiles.
# usage: bt-headset-mode toggle|call|music|status
#        bt-headset-mode watch <idle-seconds>  - go back to music once the headset mic is unused for that long

CALL_PREFIX="headset-head-unit"
MUSIC_PREFIX="a2dp-sink"
WATCH_INTERVAL=10

notify() {
  notify-send -a "Bluetooth headset" "$@" || true
}

cards() {
  pactl -f json list cards | jq -c '.[] | select(.name | startswith("bluez_card."))'
}

# highest priority available profile of a card whose name starts with the given prefix
best_profile() {
  jq -r --arg prefix "$2" '
    .profiles | to_entries
    | map(select((.key | startswith($prefix)) and .value.available))
    | max_by(.value.priority) | .key // empty' <<<"$1"
}

in_call_mode() {
  [[ "$(jq -r '.active_profile' <<<"$1")" == "$CALL_PREFIX"* ]]
}

set_mode() {
  local mode="$1" prefix card name profile switched=0
  if [ "$mode" = "call" ]; then prefix="$CALL_PREFIX"; else prefix="$MUSIC_PREFIX"; fi

  while read -r card; do
    name="$(jq -r '.name' <<<"$card")"
    profile="$(best_profile "$card" "$prefix")"
    if [ -n "$profile" ]; then
      pactl set-card-profile "$name" "$profile"
      switched=1
    fi
  done < <(cards)

  if [ "$switched" = 1 ]; then
    notify "Headset: $mode mode"
  else
    notify "No Bluetooth headset with $mode mode connected"
  fi
}

any_in_call_mode() {
  local card
  while read -r card; do
    in_call_mode "$card" && return 0
  done < <(cards)
  return 1
}

# Apps record from WirePlumber's loopback source (bluez_input.<AA:BB:...>), the raw SCO source behind it
# stays running as long as the profile is active, so only fall back to it when there is no loopback.
mic_in_use() {
  local addr="${1#bluez_card.}"
  pactl -f json list sources | jq -e --arg loop "bluez_input.${addr//_/:}" --arg raw "bluez_input.$addr." '
    map(select(.name == $loop)) as $loopback
    | (if ($loopback | length) > 0 then $loopback else map(select(.name | startswith($raw))) end)
    | any(.state == "RUNNING")' >/dev/null
}

watch() {
  local timeout="$1" card name profile
  declare -A idle=()

  while true; do
    declare -A seen=()
    while read -r card; do
      name="$(jq -r '.name' <<<"$card")"
      in_call_mode "$card" || continue
      seen[$name]=1

      if mic_in_use "$name"; then
        idle[$name]=0
        continue
      fi

      idle[$name]=$((${idle[$name]:-0} + WATCH_INTERVAL))
      if [ "${idle[$name]}" -ge "$timeout" ]; then
        profile="$(best_profile "$card" "$MUSIC_PREFIX")"
        if [ -n "$profile" ] && pactl set-card-profile "$name" "$profile"; then
          notify "Headset: music mode" "Microphone unused for ${timeout}s"
        fi
        idle[$name]=0
      fi
    done < <(cards || true)

    for name in "${!idle[@]}"; do
      [ -n "${seen[$name]:-}" ] || unset "idle[$name]"
    done
    unset seen

    sleep "$WATCH_INTERVAL"
  done
}

case "${1:-toggle}" in
  call | music) set_mode "$1" ;;
  toggle)
    if any_in_call_mode; then set_mode music; else set_mode call; fi
    ;;
  status)
    if any_in_call_mode; then echo call; else echo music; fi
    ;;
  watch) watch "${2:?idle timeout in seconds required}" ;;
  *)
    echo "usage: $0 toggle|call|music|status|watch <idle-seconds>" >&2
    exit 1
    ;;
esac
