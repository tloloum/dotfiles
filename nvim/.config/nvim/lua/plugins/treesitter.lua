return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"bash",
				"gitignore",
				"c",
				"cpp",
				"lua",
				"markdown",
				"markdown_inline",
				"vim",
				"python",
				"latex",
			},
			auto_install = true,
			highlight = { enable = true },
		})
	end,
}
