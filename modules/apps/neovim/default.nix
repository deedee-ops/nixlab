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

    home = {
      packages = [
        pkgs.lua51Packages.lua # luarocks
        pkgs.lua51Packages.luarocks # luarocks
        pkgs.nodejs # multiple LSPs
        pkgs.cargo # mason
        pkgs.deadnix # mason
        pkgs.go # mason
        pkgs.lua-language-server # mason
        pkgs.markdownlint-cli # mason
        pkgs.nixfmt-rfc-style # mason
        pkgs.python3 # mason
        pkgs.python3Packages.pip # mason
        pkgs.shellcheck # mason
        pkgs.statix # mason
        pkgs.unzip # mason
        pkgs.wget # mason
        pkgs.yamlfmt # mason
        pkgs.yamllint # mason
        pkgs.buf # null-ls
        pkgs.cue # null-ls
        pkgs.helm-ls # null-ls
        pkgs.ripgrep # telescope
        pkgs.fd # telescope-filebrowser
        pkgs.gnumake # telescope-fzf
        pkgs.gcc # tree-sitter
        pkgs.tree-sitter # tree-sitter

        # sops bash/zsh completions are broken, so disable them
        (pkgs.sops.overrideAttrs { postInstall = ""; }) # vim-sops
      ];
      activation.init-neovim-state = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! [ -f "${config.xdg.stateHome}/nvim/lazy/state.json" ]; then
          mkdir -p "${config.xdg.stateHome}/nvim/lazy"
          echo -n '{"checker":{"last_check":0}}' > "${config.xdg.stateHome}/nvim/lazy/state.json"
        fi
      '';
    };

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
