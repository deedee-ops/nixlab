# shellcheck shell=bash

if [ "$1" = "mute" ]; then
  touch /tmp/.dunst-mute
  exit 0
fi

if [ "$1" = "unmute" ]; then
  rm /tmp/.dunst-mute
  exit 0
fi

if [ "$1" = "toggle" ]; then
  if [ -f /tmp/.dunst-mute ]; then
    rm /tmp/.dunst-mute
  else
    touch /tmp/.dunst-mute
  fi
  exit 0
fi

if [ "$1" = "show" ]; then
  if [ -f /tmp/.dunst-mute ]; then
    echo "󱙍"
  else
    echo "󰍡"
  fi
  exit 0
fi
