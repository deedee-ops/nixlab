return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope, builtin = require("telescope"), require("telescope.builtin")
      telescope.setup({})

      vim.keymap.set("n", "<Leader>p", builtin.find_files, {})
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    event = "VeryLazy",
    build = "make",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local telescope, builtin = require("telescope"), require("telescope.builtin")
      telescope.load_extension("fzf")

      function Fuzzy_find_files()
        builtin.grep_string({
          path_display = { "smart" },
          only_sort_text = true,
          word_match = "-w",
          search = "",
        })
      end

      vim.keymap.set("n", "<Leader>P", "<cmd>lua Fuzzy_find_files{}<cr>", {})
    end,
  },
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = {} },
      },
    },
  },
}
