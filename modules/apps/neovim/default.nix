{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.neovim;
in
{
  options.myHomeApps.neovim = {
    enable = lib.mkEnableOption "neovim" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # stylix.targets.neovim.enable = true; # stylix is broken, even after disabling custom lua xdg

    home.packages = [
      pkgs.cargo # mason
      pkgs.deadnix # mason
      pkgs.go # mason
      pkgs.lua-language-server # mason
      pkgs.luajitPackages.luarocks # mason
      pkgs.nixfmt-rfc-style # mason
      pkgs.python3 # mason
      pkgs.shellcheck # mason
      pkgs.statix # mason
      pkgs.unzip # mason
      pkgs.wget # mason
      pkgs.ripgrep # telescope
      pkgs.fd # telescope-filebrowser
      pkgs.gnumake # telescope-fzf
      pkgs.gcc # tree-sitter
      pkgs.tree-sitter # tree-sitter
      pkgs.sops # vim-sops
    ];

    programs.neovim = {
      enable = true;

      coc.enable = false;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    xdg.configFile = {
      nvim = {
        source = ./config;
        recursive = true;
      };
    };
  };
}
