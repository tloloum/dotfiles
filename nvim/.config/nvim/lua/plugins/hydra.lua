return {
	"nvimtools/hydra.nvim",
	keys = { "<leader>s" },
	config = function()
		local Hydra = require("hydra")

		Hydra({
			name = "Resize",
			mode = "n",
			body = "<leader>s",
			hint = [[
 _h_ / _l_  largeur    _j_ / _k_  hauteur
 _=_  égaliser         _<Esc>_ / _<CR>_  sortir
]],
			config = {
				color = "red",
				invoke_on_body = true,
				hint = { float_opts = { border = "rounded" } },
				on_enter = function()
					vim.g.minianimate_disable = true
				end,
				on_exit = function()
					vim.g.minianimate_disable = false
				end,
			},
			heads = {
				{ "h",       "<C-w>3<", { desc = "réduire largeur" } },
				{ "l",       "<C-w>3>", { desc = "agrandir largeur" } },
				{ "j",       "<C-w>3-", { desc = "réduire hauteur" } },
				{ "k",       "<C-w>3+", { desc = "agrandir hauteur" } },

				{ "<Left>",  "<C-w>3<" },
				{ "<Right>", "<C-w>3>" },
				{ "<Down>",  "<C-w>3-" },
				{ "<Up>",    "<C-w>3+" },

				{ "=",       "<C-w>=",  { desc = "égaliser" } },

				{ "<Esc>",   nil,       { exit = true } },
				{ "<CR>",    nil,       { exit = true } },
				{ "q",       nil,       { exit = true } },
			},
		})
	end,
}
