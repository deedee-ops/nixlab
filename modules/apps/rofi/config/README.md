# rofi themes

> source: <https://github.com/adi1090x/rofi>

To convert hardcoded `px` units in themes, to relative `em` counterparts, use this ruby script:

```ruby
File.write('output.rasi', File.read('input.rasi').gsub(/[0-9]+px/) { |size| "#{(size[0..-3].to_i / 18.0).round(3)}em" })
```

## Invocation commands

| View            | Command                                                                                                                                                                                       |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Applications    | `rofi -show drun -theme ~/.config/rofi/drun/config.rasi`                                                                                                                                      |
| Active Windows  | `rofi -show window -theme ~/.config/rofi/drun/config.rasi`                                                                                                                                    |
| TODO Item       | `rofi -show TODO -modi TODO:~/.config/rofi/todo/todo.sh -theme ~/.config/rofi/todo/config.rasi`                                                                                               |
| Clipboard       | `rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}' -theme ~/.config/rofi/generic/config.rasi`                                                                       |
| RBW (Bitwarden) | `rofi-rbw --selector-args="-kb-move-char-back '' -theme ~/.config/rofi/generic/config.rasi" --prompt="󱉼" --keybindings="Control+b:type:username,Control+c:type:password,Control+t:type:totp"` |
