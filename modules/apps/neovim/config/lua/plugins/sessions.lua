return {
  "rmagatti/auto-session",
  config = function()
    require("auto-session").setup({
      auto_session_allowed_dirs = {
        "~/Projects/*",
        "~/.config/home-manager",
      },
      session_lens = {
        buftypes_to_ignore = {},
        load_on_setup = true,
        theme_conf = { border = true },
        previewer = false,
      },
      post_restore_cmds = { "Neotree filesystem reveal left" },
      pre_save_cmds = { "Neotree close" },
    })

    vim.keymap.set("n", "<Leader>S", require("auto-session.session-lens").search_session, { noremap = true })
  end,
}
