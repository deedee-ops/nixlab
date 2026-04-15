return {
	"auto-session",
	keys = {
		{ "<leader>S", ":AutoSession search<CR>", mode = "n", desc = "auto-session: list sessions" },
	},
	after = function()
		require("auto-session").setup({
			allowed_dirs = {
				"~/Projects/*",
			},
			session_lens = {
				picker = "snacks",
				picker_opts = {
					preset = "dropdown",
					preview = false,
				},
			},
		})

		vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
	end,
}
