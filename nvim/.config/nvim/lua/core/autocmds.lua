-- Highlight the window separator with a custom color
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("custom_highlights", { clear = true }),
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#61afef" })
	end,
})

-- Automatically resize splits when resizing Neovim window
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})
