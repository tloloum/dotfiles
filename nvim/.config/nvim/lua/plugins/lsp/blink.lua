return {
	"saghen/blink.cmp",
	version = "1.*",
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
		keymap = { preset = "default" },
		-- <Tab> = show and insert or accept single, select next
		-- S-Tab = show and insert or accept single, select previous
		-- C-n = select next
		-- C-p = select previous
		-- C-y = select and accept
		-- C-e = documentation

		cmdline = {
			keymap = {
				["<Tab>"] = { "show", "accept" },
				["<CR>"] = { "accept_and_enter", "fallback" },
			},
			completion = {
				ghost_text = { enabled = true },
				menu = {
					auto_show = function(ctx)
						return vim.fn.getcmdtype() == ":"
					end,
				},
			},
		},

		sources = {
			providers = {
				cmdline = {
					min_keyword_length = function(ctx)
						-- when typing a command, only show when the keyword is 3 characters or longer
						if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
							return 3
						end
						return 0
					end,
				},
			},
		},

		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 1000 },

			keyword = { range = "full" },

			accept = { create_undo_point = true },

			ghost_text = { show_with_selection = true },
		},
	},
}
