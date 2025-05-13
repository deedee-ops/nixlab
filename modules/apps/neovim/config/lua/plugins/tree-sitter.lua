return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      auto_install = true,
      ensure_installed = {
        -- for noice
        "bash",
        "lua",
        "markdown",
        "markdown_inline",
        "regex",
        "vim",
      },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
