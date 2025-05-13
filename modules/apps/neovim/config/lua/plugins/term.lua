return {
  {
    "voldikss/vim-floaterm",
    event = "VeryLazy",
    config = function()
      vim.keymap.set("n", "<Leader>t", ":FloatermToggle<CR>", {})
      vim.keymap.set("t", "<C-t>", "<C-\\><C-n>:FloatermToggle<CR>", {})
      vim.g.floaterm_width = 0.8
      vim.g.floaterm_height = 0.8
      vim.g.floaterm_giteditor = false
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<Leader>gg", ":LazyGit<CR>", {})
    end,
  },
}
