return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  config = function()
    require("neo-tree").setup({
      filesystem = {
        filtered_items = {
          visible = true,
        },
        window = {
          mappings = {
            ["o"] = { "open", nowait = true },
            -- need to disable other mappings to avoid delay
            -- see: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1128
            ["oc"] = "noop",
            ["od"] = "noop",
            ["og"] = "noop",
            ["om"] = "noop",
            ["on"] = "noop",
            ["os"] = "noop",
            ["ot"] = "noop",
          },
        },
      },
    })
    vim.keymap.set("n", "<Leader>kb", ":Neotree filesystem reveal toggle left<CR>", {})
  end,
}
