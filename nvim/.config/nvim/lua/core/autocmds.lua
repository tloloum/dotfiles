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


vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(ev)
		local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

		if client:supports_method('textDocument/inlayHint') then
			vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
		end

		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Go to definition' })

		vim.keymap.set('n', '<leader>th', function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
		end, { buffer = ev.buf, desc = 'Toggle Inlay Hints' })
	end,
})
