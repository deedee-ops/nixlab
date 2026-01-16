return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    lazy = true,
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      preset = "lazy",
      code = {
        conceal_delimiters = false,
        width = "full",
        border = "thin",
      },
    },
  },
}
