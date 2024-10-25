-- install lazy.vim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("config")

require("lazy").setup("plugins", {
  checker = {
    enabled = true,
    notify = false,
  },
  defaults = {
    version = "*", -- try to install stable version
  },
  install = {
    colorscheme = { "catppuccin" },
  },
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
})
