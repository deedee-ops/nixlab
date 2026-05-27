_aichat_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(aichat -r shell -e "$_old")
        zle end-of-line
    fi
}
zle -N _aichat_zsh
bindkey '^E' _aichat_zsh
