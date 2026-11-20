return {
	"mason-org/mason.nvim",
	lazy = false,
	config = function()
		require("mason").setup({
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		local ensure_installed = {
			"clangd",
			"clang-format",
			"glsl_analyzer",
			"neocmakelsp",
			"cmakelang",
			"prettier",
		}

		local registry = require("mason-registry")
		registry.refresh(function()
			for _, name in ipairs(ensure_installed) do
				local package = registry.get_package(name)
				if not package:is_installed() and not package:is_installing() then
					package:install()
				end
			end
		end)
	end,
}
