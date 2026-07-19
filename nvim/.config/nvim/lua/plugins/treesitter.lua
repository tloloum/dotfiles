return {
	"romus204/tree-sitter-manager.nvim",
	dependencies = {},
	config = function()
		require("tree-sitter-manager").setup({
			ensure_installed = {
				"bash",
				"gitignore",
				"html",
				"javascript",
				"c",
				"cpp",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"rst",
				"typescript",
				"vim",
			},
			auto_install = true,
		})
	end,
}
