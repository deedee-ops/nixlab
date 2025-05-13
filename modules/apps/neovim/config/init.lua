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

local lazyUtil = require("lazy.util")
local checkFreq = 86400 -- daily
local lastCheck = vim.json.decode(lazyUtil.read_file(vim.fn.stdpath("state") .. "/lazy/state.json")).checker.last_check

require("lazy").setup("plugins", {
  checker = {
    -- this is a hack, to enable checker only when there is actual time for a check
    -- otherwise it will slow down neovim on each run
    enabled = lastCheck + checkFreq - os.time() < 0,
    frequency = checkFreq,
    notify = true,
  },
  defaults = {
    version = "*", -- try to install stable version
  },
  install = {
    colorscheme = { "catppuccin" },
  },
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
})
