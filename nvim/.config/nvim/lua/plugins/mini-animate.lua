return {
	"echasnovski/mini.animate",
	event = "VeryLazy",
	config = function()
		local animate = require("mini.animate")
		animate.setup({
			scroll = {
				enable = true,
				timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
			},
			cursor = {
				enable = true,
				timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
			},
			resize = {
				enable = true,
				timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
			},
			open = { enable = true },
			close = { enable = true },
		})
	end,
}
