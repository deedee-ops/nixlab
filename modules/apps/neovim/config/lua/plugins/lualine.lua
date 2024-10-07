return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",
        disabled_filetypes = {
          statusline = { "neo-tree" },
        },
      },
      sections = {
        lualine_a = { "hostname", "mode" },
      },
    })
  end,
}
