return {
	"barbar.nvim",
	event = "DeferredUIEnter",
	keys = {
		{ "<leader>w", ":BufferClose<CR>", mode = "n", desc = "barbar: close tab" },
		{
			"<leader>aw",
			":BufferCloseAllButCurrentOrPinned<CR>",
			mode = "n",
			desc = "barbar: close all tabs except current one",
		},
		{ "<leader>l", "<Cmd>BufferNext<CR>", mode = "n", desc = "barbar: next tab" },
		{ "<leader>h", "<Cmd>BufferPrevious<CR>", mode = "n", desc = "barbar: previous tab" },
	},
	after = function()
		require("barbar").setup({
			animation = false,
			clickable = false,
			no_name_title = "New Tab",
		})
	end,
}
