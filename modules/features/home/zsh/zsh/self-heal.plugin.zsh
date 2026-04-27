_fix_terminal_state() {
  local stty_out
  stty_out=$(stty -a 2>/dev/null)

  # Detect broken state: -icanon (raw mode), -echo, or -isig (no signal processing = no ctrl+c)
  if [[ "$stty_out" == *"-isig"* || "$stty_out" == *"-icanon"* || "$stty_out" == *"-echo"* ]]; then
    stty sane
  fi

  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l'
  printf '\e[?1049l'
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _fix_terminal_state
