return {
	"snacks.nvim",
	event = "DeferredUIEnter",
	keys = {
		{ "<leader>w", ":BufferClose<CR>", mode = "n", desc = "barbar: close tab" },
		{
			"<leader>kb",
			function()
				Snacks.explorer()
			end,
			mode = "n",
			desc = "snacks: show file explorer",
		},
		{
			"<leader>kk",
			function()
				Snacks.picker.keymaps()
			end,
			mode = "n",
			desc = "snacks: show keymaps",
		},
		{
			"<leader>p",
			function()
				Snacks.picker.files()
			end,
			mode = "n",
			desc = "snacks: show file picker",
		},
		{
			"<leader>P",
			function()
				Snacks.picker.grep()
			end,
			mode = "n",
			desc = "snacks: show file contents grepper picker",
		},
		{
			"<leader>t",
			function()
				Snacks.picker.grep({
					live = false,
					regex = true,
					search = "(@(todo|fix(me)?|hack|warn|note))|((TODO|FIX(ME)?|HACK|WARN|NOTE):)",
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			mode = "n",
			desc = "snacks: show todo/fixme comments",
		},
		-- LSP
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			mode = "n",
			desc = "snacks: LSP - goto definition",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_declarations()
			end,
			mode = "n",
			desc = "snacks: LSP - goto declaration",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			mode = "n",
			nowait = true,
			desc = "snacks: LSP - references",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			mode = "n",
			desc = "snacks: LSP - goto implementation",
		},
		{
			"gt",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			mode = "n",
			desc = "snacks: LSP goto type definition",
		},
	},
	after = function()
		require("snacks").setup({
			picker = {
				layout = { preset = "ivy" },
				matcher = { frecency = true },
				win = {
					input = {
						keys = {
							["o"] = { "confirm", mode = { "n" } },
						},
					},
				},
				sources = {
					grep = {
						debug = {
							scores = true, -- show frecency scores
						},
					},
					explorer = {
						hidden = true,
						win = {
							list = {
								keys = {
									["o"] = "confirm",
								},
							},
						},
					},
				},
			},
		})
	end,
}
