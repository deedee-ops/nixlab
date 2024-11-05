_: {
  imports = [
    ./core.nix
    ./theme.nix

    # Terminal apps
    ./aichat
    ./bat
    ./btop
    ./direnv
    ./fzf
    ./git
    ./gnupg
    ./kubernetes
    ./neovim
    ./ssh
    ./wakatime
    ./xdg-ninja
    ./zsh

    # GUI apps
    ./xorg

    ./alacritty
    ./awesome
    ./dunst
    ./firefox
    ./mpv
    ./redshift
    ./syncthing
    ./thunderbird
  ];
}
