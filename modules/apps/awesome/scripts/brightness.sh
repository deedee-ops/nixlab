# shellcheck shell=bash

PERCENTAGE_STEP=5

lcddevice="$(echo /sys/class/backlight/*)"
kbddevice="$(echo /sys/class/leds/*kbd_backlight)"
lcdmax="$(cat "${lcddevice}/max_brightness")"
kbdmax="$(cat "${kbddevice}/max_brightness")"
step="$(( lcdmax / "$((100 / PERCENTAGE_STEP))" ))"

function lcdUp {
  current="$(cat "${lcddevice}/brightness")"
  val="$(( current + step ))"
  if [[ $val -gt $lcdmax ]]; then
    val="$lcdmax"
  fi
  echo "$val" > "${lcddevice}/brightness"
}

function lcdDown {
  current="$(cat "${lcddevice}/brightness")"
  val="$(( current - step ))"
  if [[ $val -lt 0 ]]; then
    val=0
  fi
  echo "$val" > "${lcddevice}/brightness"
}

function kbdUp {
  current="$(cat "${kbddevice}/brightness")"
  val="$(( current + 1 ))"
  if [[ $val -gt $kbdmax ]]; then
    val="$kbdmax"
  fi
  echo "$val" > "${kbddevice}/brightness"
}

function kbdDown {
  current="$(cat "${kbddevice}/brightness")"
  val="$(( current - 1 ))"
  if [[ $val -lt 0 ]]; then
    val=0
  fi
  echo "$val" > "${kbddevice}/brightness"
}

function output {
  current="$(cat "${lcddevice}/brightness")"
  perc_val="$(echo "${current} ${lcdmax}" | awk '{ print int($1 / $2 * 100)}')"
  echo " ${perc_val}%"
}

case "$1" in
  --lcdUp)
    lcdUp
    output
    ;;
  --lcdDown)
    lcdDown
    output
    ;;
  --kbdUp)
    kbdUp
    output
    ;;
  --kbdDown)
    kbdDown
    output
    ;;
  *)
    output
    ;;
esac

