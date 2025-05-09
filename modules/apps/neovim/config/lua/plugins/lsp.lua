return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ansiblels",
          "bashls",
          "golangci_lint_ls",
          "gopls",
          "jsonls",
          -- "lua_ls", -- installed by nix
          "nil_ls",
          "yamlls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    commit = "36f21ab9555dacac485f35059e20f327501320d5", -- https://github.com/williamboman/mason-lspconfig.nvim/issues/469
    config = function()
      local lspconfig = require("lspconfig")

      lspconfig.ansiblels.setup({})
      lspconfig.bashls.setup({})
      lspconfig.golangci_lint_ls.setup({})
      lspconfig.gopls.setup({})
      lspconfig.jsonls.setup({})
      lspconfig.lua_ls.setup({})
      lspconfig.nil_ls.setup({
        settings = {
          ["nil"] = {
            formatting = {
              command = { "nixfmt" },
            },
          },
        },
      })
      lspconfig.rubocop.setup({
        cmd = { "bundle", "exec", "rubocop", "--lsp" },
      })
      lspconfig.solargraph.setup({
        cmd = { "bundle", "exec", "solargraph", "stdio" },
      })
      lspconfig.yamlls.setup({})

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set({ "n", "v" }, "gc", vim.lsp.buf.code_action, {})
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "gf", function()
        vim.lsp.buf.format({ async = true })
      end, {})
      vim.keymap.set("n", "gh", vim.diagnostic.goto_prev, {})
      vim.keymap.set("n", "gl", vim.diagnostic.goto_next, {})
      vim.keymap.set("n", "gj", vim.diagnostic.open_float, {})
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")

      local diagnostics = null_ls.builtins.diagnostics
      local formatting = null_ls.builtins.formatting

      null_ls.setup({
        sources = {
          -- these should be handled by LSP
          -- diagnostics.ansiblelint
          -- diagnostics.golangci_lint,
          -- diagnostics.rubocop,
          -- formatting.rubocop,

          diagnostics.actionlint.with({
            extra_args = { "-config-file", ".github/actionlint.yaml" },
          }), -- github actions
          diagnostics.buf, -- protobuf
          diagnostics.cue_fmt, -- cue files
          diagnostics.deadnix, -- nix
          diagnostics.hadolint, -- dockerfile
          diagnostics.markdownlint, -- markdown
          diagnostics.statix, -- nix
          diagnostics.yamllint, -- yaml

          formatting.buf, -- protobufs
          formatting.cue_fmt, -- cue files
          formatting.gofumpt, -- golang
          formatting.goimports, -- golang
          formatting.golines.with({
            extra_args = { "-m", "160", "-t", "2" },
          }), -- golang
          formatting.nixfmt, -- nix
          formatting.prettierd.with({
            extra_filetypes = { "json5" },
          }), -- json
          formatting.stylua, -- lua
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "actionlint",
          "ansible-language-server",
          "bash-language-server",
          "goimports",
          "golangci-lint-langserver",
          "golines",
          "gopls",
          "hadolint",
          "json-lsp",
          -- "lua-language-server", -- installed by nix
          "luacheck",
          "nil",
          "nixpkgs-fmt",
          "prettierd",
          "stylua",
          "yaml-language-server",
          "yamllint",
        },
        run_on_start = true,
        auto_update = true,
      })
    end,
  },
}
