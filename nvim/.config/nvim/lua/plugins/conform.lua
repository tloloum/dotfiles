return {
	"stevearc/conform.nvim",
	opts = {},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				css = { "prettier" },
				json = { "prettier" },
				html = { "prettier" },
				lua = { "stylua" },
				markdown = { "prettier" },
				python = { "ruff_fix", "ruff_format" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				cpp = { "clang_format" },
				c = { "clang_format" },
				glsl = { "clang_format" },
				cmake = { "gersemi" },
				tex = { "tex-fmt" },
				yaml = { "prettier" },
			},

			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 3000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>F", function()
			conform.format({
				lsp_format = "fallback",
				async = false,
				timeout_ms = 3000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
