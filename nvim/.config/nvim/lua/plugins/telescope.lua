return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {

				prompt_prefix = " ",
				selection_caret = " ",
				path_display = { "smart" },
				file_ignore_patterns = { ".git/", "node_modules" },

				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					},
				},
			},
		})

		telescope.load_extension("fzf")

		local keymap = vim.keymap

		keymap.set("n", "<leader>ff", function()
			require("telescope.builtin").find_files({ hidden = true })
		end, { desc = "Recherche noms fichiers" })
		keymap.set(
			"n",
			"<leader>fr",
			"<cmd>Telescope live_grep<cr>",
			{ desc = "Recherche dans fichiers" }
		)
	end,
}
