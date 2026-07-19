return {
	"kdheepak/lazygit.nvim",
	lazy = true,
	cmd = {
		"LazyGit",
		"LazyGitCurrentFile",
		"LazyGitFilterCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentLine",
	},

	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	keys = {
		{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
	},
}
