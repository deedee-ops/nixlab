setopt PROMPT_SUBST

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_KUBERNETES_PROMPT_PREFIX="%{$reset_color%}%{$fg[blue]%}["
ZSH_THEME_KUBERNETES_PROMPT_SUFFIX="]%{$reset_color%}"

local host="$(hostname -s 2> /dev/null || cat /etc/hostname)"

if [ "$UID" = "0" ]; then
  PROMPT='%{$bg[red]$fg[black]%} ${host:u} %{$reset_color%}$(kubernetes_custom_status)$(git_custom_status)%{$fg[red]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
else
  PROMPT='%{$bg[${PROMPT_HOSTNAME_COLOR:-magenta}]$fg[black]%} ${host:u} %{$reset_color%}$(kubernetes_custom_status)$(git_custom_status)%{$fg[cyan]%}[%~% ]%{$reset_color%}%B%(!.#.$)%b '
fi
