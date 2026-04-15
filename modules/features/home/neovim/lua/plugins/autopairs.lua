return {
	"nvim-autopairs",
	event = "DeferredUIEnter",
	after = function()
		local npairs = require("nvim-autopairs")

		npairs.setup()
		npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
		npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
	end,
}
