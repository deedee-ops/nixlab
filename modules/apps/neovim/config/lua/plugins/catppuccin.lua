return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      integrations = {
        barbar = true,
        mason = true,
        neotree = true,
        treesitter = true,
        telescope = true,
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
