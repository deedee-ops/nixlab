return {
  {
    "voldikss/vim-floaterm",
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
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<Leader>gg", ":LazyGit<CR>", {})
    end,
  },
}
