# [Home] - Go to beginning of line
bindkey "^[[H" beginning-of-line

# [End] - Go to end of line
bindkey "^[[F"  end-of-line

# [Backspace] - delete backward
bindkey '^?' backward-delete-char

# [Delete] - delete forward
bindkey "^[[3~" delete-char

# [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5C' forward-word

# [Ctrl-LeftArrow] - move backward one word
bindkey '^[[1;5D' backward-word

