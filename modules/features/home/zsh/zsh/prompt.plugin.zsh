setopt PROMPT_SUBST

local host="$(hostname -s 2> /dev/null || cat /etc/hostname)"

if [ "$UID" = "0" ]; then
  PROMPT='%{$bg[red]$fg[black]%} ${host:u} %{$reset_color%}$(typeset -f kubernetes_custom_status &>/dev/null && kubernetes_custom_status)$(typeset -f git_custom_status &>/dev/null && git_custom_status)%{$fg[red]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
else
  PROMPT='%{$bg[${PROMPT_HOSTNAME_COLOR:-magenta}]$fg[black]%} ${host:u} %{$reset_color%}$(typeset -f kubernetes_custom_status &>/dev/null && kubernetes_custom_status)$(typeset -f git_custom_status &>/dev/null && git_custom_status)%{$fg[cyan]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
fi
