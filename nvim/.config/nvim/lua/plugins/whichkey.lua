return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	dependencies = {
		-- Moteur d'icônes : which-key le détecte et l'utilise en priorité.
		{ "echasnovski/mini.icons", opts = {} },
		"nvim-tree/nvim-web-devicons", -- fallback
	},
	opts = {
		-- Préréglage de présentation : "classic" | "modern" | "helix".
		preset = "modern",
		-- Délai (ms) avant que le popup s'ouvre après le préfixe.
		delay = 300,
		icons = {
			-- Active les icônes ; couleurs tirées de mini.icons.
			mappings = true,
			colors = true,
			-- Règles auto supplémentaires (s'ajoutent aux règles intégrées).
			rules = {
				{ pattern = "format", icon = "󰉼", color = "cyan" },
			},
		},
		-- Position/rendu de la fenêtre.
		win = {
			border = "rounded", -- none | single | double | rounded
			padding = { 1, 2 },
		},
		-- Disposition des colonnes de la liste.
		layout = {
			spacing = 4,
		},
		-- Coupe les avertissements pour les mappings sans desc.
		notify = false,
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Raccourcis du buffer (which-key)",
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Groupes : icône colorée + ordre d'affichage (order < 1000 => remonte).
		-- Les entrées sans `order` valent 1000 et suivent, triées normalement.
		wk.add({
			{ "<leader>b", desc = "Buffer", icon = { icon = "󰆧", color = "blue" }, order = 1 },
			{ "<leader>bo", desc = "Order", icon = { icon = "󰆧", color = "blue" } },
			{ "<leader>bs", desc = "Split", icon = { icon = "󰆧", color = "blue" } },
			{ "<leader>bc", desc = "Close", icon = { icon = "󰆧", color = "blue" } },
			{ "<leader>f", group = "Find (Telescope)", icon = { icon = "", color = "green" }, order = 25 },
			{ "<leader>c", group = "Code (LSP)", icon = { icon = "", color = "yellow" }, order = 2 },
			{ "<leader>r", group = "Rename (LSP)", icon = { icon = "", color = "orange" }, order = 3 },
			{ "<leader>h", group = "Git hunks", icon = { icon = "", color = "red" }, order = 4 },
			{ "<leader>x", group = "Diagnostics", icon = { icon = "", color = "purple" }, order = 5 },
			{ "<leader>w", group = "Fenêtres", icon = { icon = "", color = "blue" }, order = 6 },
			{ "<leader>t", group = "TODO / Themes ", icon = { icon = "", color = "cyan" }, order = 7 },
			{ "<leader>d", desc = "Diagnostic (ligne)", icon = { icon = "", color = "yellow" }, order = 20 },
			{ "<leader>D", desc = "Diagnostics (buffer)", icon = { icon = "", color = "yellow" }, order = 21 },
			{ "<leader>F", desc = "Formater le buffer", icon = { icon = "󰉼", color = "cyan" }, order = 22 },
			{ "<leader>e", desc = "Explorateur", icon = { icon = "", color = "green" }, order = 23 },
			{ "<leader>q", desc = "Fermer le buffer", icon = { icon = "󰅖", color = "red" }, order = 24 },
		})
	end,
}
