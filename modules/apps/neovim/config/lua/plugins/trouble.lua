return {
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    opts = {
      open_no_results = true,
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>kt",
        "<cmd>Trouble todo toggle<cr>",
        desc = "TODO (Trouble)",
      },
    },
  },
}
