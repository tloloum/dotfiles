return {
	"olimorris/onedarkpro.nvim",
	priority = 1000,
	config = function()
		-- Appliqué ici, avant l'UIEnter : la cascade ColorScheme se propage
		-- normalement (surlignages personnalisés, thème lualine, etc.)
		vim.cmd.colorscheme("onedark")
	end,
}
