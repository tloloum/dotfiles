require("core")
require("config.lazy")

vim.lsp.enable({
	"lua_ls",
	"clangd",
	"bashls",
	"pyright",
})
