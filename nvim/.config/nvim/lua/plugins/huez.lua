return {
	"vague2k/huez.nvim",
	branch = "main",
	event = "UIEnter",
	keys = {
		{ "<leader>th", "<cmd>Huez<cr>", desc = "Change theme" },
	},
	config = function()
		require("huez").setup({
			fallback = "onedark",
		})
	end,
}
