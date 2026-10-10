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

        withPython3 = false;
        withRuby = false;
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

        runtimePkgs = [
          pkgs.curl
          pkgs.git
          pkgs.ripgrep
          pkgs.sops
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
              pkgs.vimPlugins.bufdelete-nvim
              pkgs.vimPlugins.vim-helm
              pkgs.vimPlugins.vim-surround
              pkgs.vimPlugins.vim-wakatime
              (pkgs.vimUtils.buildVimPlugin {
                pname = "sops-nvim";
                version = "0-unstable-2026-09-12";
                src = pkgs.fetchFromGitHub {
                  owner = "trixnz";
                  repo = "sops.nvim";
                  rev = "26592d8fab2a4c133d2a5d95e90d2ba54eb3c018";
                  hash = "sha256-SXlI2M2BjNKEbReqTnNXITmryAboPjQJmq1IcgAMc5A=";
                };
              })
            ];
          };

          lazyPlugins = {
            lazy = true;
            data = [
              pkgs.vimPlugins.bufferline-nvim
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
