{ self, inputs, ... }:
{
  flake.homeModules.features-home-neovim =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        package = self.packages."${pkgs.stdenv.hostPlatform.system}".neovim;

        coc.enable = false;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;
        settings.config_directory = ./.;

        imports = [
          self.modules.neovim.lsp

          self.modules.neovim."${self.theme.name}"
        ];

        extraPackages = [
          pkgs.curl
          pkgs.git
          pkgs.ripgrep
        ];

        specs = {
          init = {
            data = null;
            before = [ "INIT_MAIN" ];
            config = "require('init')";
          };

          plugins = {
            data = [
              # plugin manager
              pkgs.vimPlugins.lz-n

              # base dependencies
              pkgs.vimPlugins.blink-cmp
              pkgs.vimPlugins.colorful-menu-nvim
              pkgs.vimPlugins.lspkind-nvim
              pkgs.vimPlugins.nvim-treesitter.withAllGrammars
              pkgs.vimPlugins.nvim-web-devicons
              pkgs.vimPlugins.plenary-nvim

              # plugins
              pkgs.vimPlugins.auto-session
              pkgs.vimPlugins.vim-helm
              pkgs.vimPlugins.vim-surround
              pkgs.vimPlugins.vim-wakatime
            ];
          };

          lazyPlugins = {
            lazy = true;
            data = [
              pkgs.vimPlugins.barbar-nvim
              pkgs.vimPlugins.comment-nvim
              pkgs.vimPlugins.conform-nvim
              pkgs.vimPlugins.lazydev-nvim
              pkgs.vimPlugins.lualine-nvim
              pkgs.vimPlugins.nvim-autopairs
              pkgs.vimPlugins.nvim-lint
              pkgs.vimPlugins.snacks-nvim
            ];
          };
        };
      };
    };
}
