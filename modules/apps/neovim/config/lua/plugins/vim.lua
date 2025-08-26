return {
  {
    -- library used by most plugins
    -- use master, as stable version is old
    "nvim-lua/plenary.nvim",
    version = false,
  },
  {
    "tpope/vim-surround", -- change surrounding quotations
  },
  {
    "dhruvasagar/vim-table-mode", -- markdown tables
    event = "VeryLazy",
  },
  {
    "towolf/vim-helm", -- vim helm code highlight
  },
}
