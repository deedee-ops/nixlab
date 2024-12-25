# shellcheck shell=bash

device="$(echo /sys/class/power_supply/BAT*)"
status="$(cat "${device}/status")"
capacity="$(cat "${device}/capacity")"

if [ "$1" = "--toggle-hibernate" ]; then
  if [ -f /tmp/.battery-ignore ]; then
    rm /tmp/.battery-ignore
  else
    touch /tmp/.battery-ignore
  fi
fi

if [[ $status == "Discharging" ]]; then
  if [[ $capacity -lt 20 ]]; then
    icon=""
  elif [[ $capacity -lt 40 ]]; then
    icon=""
  elif [[ $capacity -lt 60 ]]; then
    icon=""
  elif [[ $capacity -lt 80 ]]; then
    icon=""
  else
    icon=""
  fi
  if [ -f /tmp/.battery-ignore ]; then
    icon="󱞜"
  fi
else
  icon=""
fi

params="$(cat "${device}/charge_now") $(cat "${device}/current_now") $(cat "${device}/charge_full")"
if [[ $status == "Discharging" ]]; then
  time_left="$(echo "${params}" | awk '{ print $1 / $2 }')"
else
  time_left="$(echo "${params}" | awk '{ print ($3 - $1) / $2 }')"
fi

hours="$(echo "${time_left}" | awk '{ print int($1) }')"
minutes="$(echo "${time_left} ${hours}" | awk '{ print int(($1 - $2) * 60) }')"

echo "${icon} ${capacity}% (${hours}h${minutes}m)"
