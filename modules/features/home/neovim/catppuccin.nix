{ self, ... }:
{
  flake.modules.neovim.catppuccin =
    { pkgs, ... }:
    {
      config = {
        specs.catppuccin = {
          data = pkgs.vimPlugins.catppuccin-nvim;
          config = ''
            require("catppuccin").setup({
              flavour = "${self.theme.style}";
              integrations = {
                blink_cmp = true,
                bufferline = true,
                lualine = true,
                snacks = true,
              },
            })
            vim.cmd.colorscheme("catppuccin-nvim")
          '';
        };
      };
    };
}
