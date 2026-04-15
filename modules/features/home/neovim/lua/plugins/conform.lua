return {
	"conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	after = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				go = { "gofumpt", "goimports", "golines" },
				json = { "prettierd" },
				json5 = { "prettierd" },
				jsonnet = { "jsonnetfmt" },
				lua = { "stylua" },
				markdown = { "markdownlint-cli2" },
				ruby = { "rubocop" },
				yaml = { "yamlfmt" },
			},
			formatters = {
				yamlfmt = {
					prepend_args = { "-formatter", "indent=2,include_document_start=true" },
				},
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = {
				lsp_format = "fallback",
				timeout_ms = 500,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>gf", function()
			conform.format()
		end)
	end,
}
