return {
  "numToStr/Comment.nvim",
  event = "VeryLazy",
  config = function()
    require("Comment").setup({
      mappings = {
        basic = false,
        extra = false,
      },
    })

    local api = require("Comment.api")

    vim.keymap.set("n", "<Leader>/", api.call("toggle.linewise.current", "g@$"), { expr = true })
    vim.keymap.set("v", "<Leader>/", api.call("toggle.linewise", "g@"), { expr = true })
  end,
}
