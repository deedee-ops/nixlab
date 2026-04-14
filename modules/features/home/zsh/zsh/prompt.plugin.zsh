setopt PROMPT_SUBST

local host="$(hostname -s 2> /dev/null || cat /etc/hostname)"

KUBERNETES_CUSTOM_STATUS="$(typeset -f kubernetes_custom_status &>/dev/null && kubernetes_custom_status)"
GIT_CUSTOM_STATUS="$(typeset -f git_custom_status &>/dev/null && git_custom_status)"

if [ "$UID" = "0" ]; then
  PROMPT='%{$bg[red]$fg[black]%} ${host:u} %{$reset_color%}${KUBERNETES_CUSTOM_STATUS}${GIT_CUSTOM_STATUS}%{$fg[red]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
else
  PROMPT='%{$bg[${PROMPT_HOSTNAME_COLOR:-magenta}]$fg[black]%} ${host:u} %{$reset_color%}${KUBERNETES_CUSTOM_STATUS}${GIT_CUSTOM_STATUS}%{$fg[cyan]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
fi
