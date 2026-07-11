return {
	"mrloop/telescope-git-branch.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		local telescope = require("telescope")
		telescope.load_extension("git_branch")

		vim.keymap.set({ 'n', 'v' }, '<leader>fg', function()
			require('git_branch').files()
		end, { desc = " Git diff " })
	end
}
