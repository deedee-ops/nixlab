return {
	"bufferline.nvim",
	event = "DeferredUIEnter",
	keys = {
		{ "<leader>w", "<Cmd>Bdelete<CR>", mode = "n", desc = "bufferline: close tab" },
		{
			"<leader>aw",
			"<Cmd>BufferLineCloseOthers<CR>",
			mode = "n",
			desc = "bufferline: close all tabs except current one",
		},
		{ "<leader>l", "<Cmd>BufferLineCycleNext<CR>", mode = "n", desc = "bufferline: next tab" },
		{ "<leader>h", "<Cmd>BufferLineCyclePrev<CR>", mode = "n", desc = "bufferline: previous tab" },
	},
	after = function()
		require("bufferline").setup({
			options = {
				highlights = require("catppuccin.special.bufferline").get_theme(),
				close_command = function(bufnr)
					require("bufdelete").bufdelete(bufnr, false)
				end,
				name_formatter = function(buf)
					if buf.name == "" then
						return "New Tab"
					end
				end,
			},
		})
	end,
}
