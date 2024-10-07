-- set leader
vim.g.mapleader = ","

-- disable mouse
vim.opt.mouse = ""

-- close vim
vim.keymap.set("n", "<Leader>s", ":w!<CR>", {})
vim.keymap.set("n", "<Leader>q", ":qa<CR>", {})
vim.keymap.set("n", "<Leader>Q", ":qa!<CR>", {})

-- code identation
vim.keymap.set("n", "<Tab>", ">>", {})
vim.keymap.set("n", "<S-Tab>", "<<i", {})
vim.keymap.set("i", "<S-Tab>", "<Esc><<i", {})
vim.keymap.set("v", "<Tab>", ">gv", {})
vim.keymap.set("v", "<S-Tab>", "<gv", {})

-- move around splits
vim.keymap.set("i", "<C-j>", "<Esc><C-W>j", {})
vim.keymap.set("i", "<C-k>", "<Esc><C-W>k", {})
vim.keymap.set("i", "<C-h>", "<Esc><C-W>h", {})
vim.keymap.set("i", "<C-l>", "<Esc><C-W>l", {})
vim.keymap.set("n", "<C-j>", "<Esc><C-W>j", {})
vim.keymap.set("n", "<C-k>", "<Esc><C-W>k", {})
vim.keymap.set("n", "<C-h>", "<Esc><C-W>h", {})
vim.keymap.set("n", "<C-l>", "<Esc><C-W>l", {})

-- show line numbers
vim.cmd("set number")
vim.cmd("set relativenumber")

-- tab width
vim.cmd("set tabstop=2 shiftwidth=2 expandtab")

-- allow to switch buffer without saving
vim.cmd("set hidden")

-- make search better
vim.cmd("set incsearch")
vim.cmd("set hlsearch")
vim.cmd("set ignorecase")
vim.cmd("set smartcase")

-- sane backspace
vim.cmd("set backspace=indent,eol,start")

-- force english locale
vim.cmd("language en_US.UTF-8")

-- disable arrow keys, to force usage of hjkl
vim.keymap.set("i", "<Up>", "<NOP>", {})
vim.keymap.set("i", "<Down>", "<NOP>", {})
vim.keymap.set("i", "<Left>", "<NOP>", {})
vim.keymap.set("i", "<Right>", "<NOP>", {})
vim.keymap.set("n", "<Up>", "<NOP>", {})
vim.keymap.set("n", "<Down>", "<NOP>", {})
vim.keymap.set("n", "<Left>", "<NOP>", {})
vim.keymap.set("n", "<Right>", "<NOP>", {})

-- strip whitespaces on save
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    if vim.b.noStripWhitespace then
      return
    end

    local save_cursor = vim.fn.getpos(".")
    pcall(function()
      vim.cmd([[%s/\s\+$//e]])
    end)
    vim.fn.setpos(".", save_cursor)
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "sql" }, -- ignore whitespace stripping on sql files
  callback = function()
    vim.b.noStripWhitespace = 1
  end,
})
