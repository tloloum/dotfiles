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
		clickable = true,
		sidebar_filetypes = {
			NvimTree = true,
		},
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
		{ "<leader>bcc", "<cmd>BufferCloseAllButCurrent<cr>",  desc = "All But Current" },
		{ "<leader>bco", "<cmd>BufferCloseAllButPinned<cr>",   desc = "All But Pinned" },
		{ "<leader>boh", "<cmd>BufferMovePrevious<cr>",        desc = "Move Left" },
		{ "<leader>bol", "<cmd>BufferMoveNext<cr>",            desc = "Move Right" },
		{ "<leader>boh", "<cmd>BufferMovePrevious<cr>",        desc = "Move Left" },
		{ "<leader>bob", "<cmd>BufferOrderByBufferNumber<cr>", desc = "Buffer Number" },
		{ "<leader>bon", "<cmd>BufferOrderByName<cr>",         desc = "Name" },
		{ "<leader>bod", "<cmd>BufferOrderByDirectory<cr>",    desc = "Directory" },
	},
}
