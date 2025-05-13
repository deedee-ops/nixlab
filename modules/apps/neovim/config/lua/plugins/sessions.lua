return {
  "rmagatti/auto-session",
  lazy = false,
  config = function()
    require("auto-session").setup({
      allowed_dirs = {
        "~/Projects/*",
      },
      session_lens = {
        buftypes_to_ignore = {},
        load_on_setup = false,
        theme_conf = { border = true },
        previewer = false,
      },
      pre_save_cmds = { "Neotree close" },
    })

    vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
    vim.keymap.set("n", "<Leader>S", ":SessionSearch<cr>", { noremap = true })
  end,
}
