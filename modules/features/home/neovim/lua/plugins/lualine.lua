return {
	"lualine.nvim",
	event = "DeferredUIEnter",
	after = function()
		require("lualine").setup({
			options = {
				theme = "auto",
			},
			sections = {
				lualine_a = { "hostname", "mode" },
				lualine_y = { "lsp_status" },
			},
		})
	end,
}
