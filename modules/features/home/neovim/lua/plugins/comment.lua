return {
	"comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	after = function()
		require("Comment").setup({
			mappings = {
				basic = false,
				extra = false,
			},
		})

		local api = require("Comment.api")

		vim.keymap.set(
			"n",
			"<Leader>/",
			api.call("toggle.linewise.current", "g@$"),
			{ expr = true, desc = "comment: toggle comment on a line" }
		)
		vim.keymap.set(
			"v",
			"<Leader>/",
			api.call("toggle.linewise", "g@"),
			{ expr = true, desc = "comment: toggle comment on a selection" }
		)
	end,
}
