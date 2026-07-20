return {
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			},
			diagnostics = {
				globals = { 'vim' },
			},
			workspace = {
				library = {
					vim.env.VIMRUNTIME .. "/lua",
					vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
				},
			},
		},
	}
}
