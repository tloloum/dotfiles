return {
	"vague2k/huez.nvim",
	branch = "main",
	event = "UIEnter",
	config = function()
		require("huez").setup({
			fallback = "onedark",
		})
	end,
}
