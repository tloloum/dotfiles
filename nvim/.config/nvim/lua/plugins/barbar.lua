return {
	"romgrk/barbar.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	lazy = false,
	init = function()
		vim.g.barbar_auto_setup = false
	end,
	opts = {
		animation = true,
		sidebar_filetypes = {
			NvimTree = true,
		},
		clickable = true,
		icons = {
			button = "",
			modified = { button = "●" },
			separator = { left = "▎", right = "" },
			pinned = { button = "", filename = true },
			tabpages = true,
		},
	},
	keys = {
		{ "<leader>bl",  "<cmd>BufferNext<cr>",                desc = "Next" },
		{ "<leader>bh",  "<cmd>BufferPrevious<cr>",            desc = "Previous" },
		{ "<leader>br",  "<cmd>BufferPick<cr>",                desc = "First Letter" },
		{ "<leader>bq",  "<cmd>BufferClose<cr>",               desc = "Close" },
		{ "<leader>bp",  "<cmd>BufferPin<cr>",                 desc = "Pin" },
		{ "<leader>bcp", "<cmd>BufferCloseAllButCurrent<cr>",  desc = "Close All But Current" },
		{ "<leader>boh", "<cmd>BufferMovePrevious<cr>",        desc = "Move Left" },
		{ "<leader>bol", "<cmd>BufferMoveNext<cr>",            desc = "Move Right" },
		{ "<leader>boh", "<cmd>BufferMovePrevious<cr>",        desc = "Move Left" },
		{ "<leader>bob", "<cmd>BufferOrderByBufferNumber<cr>", desc = "Buffer Number" },
		{ "<leader>bon", "<cmd>BufferOrderByName<cr>",         desc = "Name" },
		{ "<leader>bod", "<cmd>BufferOrderByDirectory<cr>",    desc = "Directory" },
	},
}
