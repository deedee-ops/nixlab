return {
  "romgrk/barbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("barbar").setup({
      animation = false,
      clickable = false,
      no_name_title = "New Tab",
    })

    vim.keymap.set("n", "<Leader>w", ":BufferClose<CR>", {})
    vim.keymap.set("n", "<Leader>aw", ":BufferCloseAllButCurrentOrPinned<CR>", {})
    vim.keymap.set("n", "<Leader>l", "<Cmd>BufferNext<CR>", {})
    vim.keymap.set("n", "<Leader>h", "<Cmd>BufferPrevious<CR>", {})
  end,
}
