_: {
  imports = [
    ./core.nix
    ./theme.nix
    ./_scripts

    # Terminal apps
    ./aichat
    ./atuin
    ./bat
    ./btop
    ./direnv
    ./freerdp
    ./fzf
    ./git
    ./gnupg
    ./kubernetes
    ./minio-client
    ./mitmproxy
    ./neovim
    ./qrtools
    ./ssh
    ./wakatime
    ./xdg-ninja
    ./yt-dlp
    ./zellij
    ./zsh

    # GUI apps
    ./xorg

    ./alacritty
    ./awesome
    ./caffeine
    ./chiaki-ng
    ./discord
    ./dunst
    ./firefox
    ./ghostty
    ./kitty
    ./mpv
    ./obsidian
    ./planify
    ./redshift
    ./rofi
    ./rustdesk
    ./slack
    ./speedcrunch
    ./syncthing
    ./teams
    ./telegram
    ./thunderbird
    ./ticktick
    ./todoist
    ./ulauncher
    ./whatsie
    ./workrave
    ./yazi
    ./zathura
    ./zoom
  ];
}
