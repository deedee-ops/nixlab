vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("autoupdate", { clear = true }),
  callback = function()
    -- lazyvim
    if require("lazy.status").has_updates then
      require("lazy").update({ show = false })
    end

    -- mason
    vim.api.nvim_command(":MasonUpdate")
  end,
})
