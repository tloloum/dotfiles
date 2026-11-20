return {
	"echasnovski/mini.starter",
	version = false,
	config = function()
		local starter = require("mini.starter")

		local FONT = {
			["0"] = { "███", "█ █", "█ █", "█ █", "███" },
			["1"] = { "  █", "  █", "  █", "  █", "  █" },
			["2"] = { "███", "  █", "███", "█  ", "███" },
			["3"] = { "███", "  █", "███", "  █", "███" },
			["4"] = { "█ █", "█ █", "███", "  █", "  █" },
			["5"] = { "███", "█  ", "███", "  █", "███" },
			["6"] = { "███", "█  ", "███", "█ █", "███" },
			["7"] = { "███", "  █", "  █", "  █", "  █" },
			["8"] = { "███", "█ █", "███", "█ █", "███" },
			["9"] = { "███", "█ █", "███", "  █", "███" },
			[":"] = { "   ", " █ ", "   ", " █ ", "   " },
		}

		-- SCALE_X = 2 * SCALE_Y
		local SCALE_X, SCALE_Y = 2, 1

		local function clock()
			local rows = {}
			for ch in os.date("%H:%M"):gmatch(".") do
				local glyph = FONT[ch]
				for i, src in ipairs(glyph) do
					local wide = src:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
						return c:rep(SCALE_X)
					end)
					for j = 1, SCALE_Y do
						local row = (i - 1) * SCALE_Y + j
						rows[row] = (rows[row] or "") .. wide .. string.rep(" ", SCALE_X)
					end
				end
			end
			return table.concat(rows, "\n")
		end

		local function center_header(content)
			local lines = starter.content_to_lines(content)
			local max_width = 0
			for _, l in ipairs(lines) do
				max_width = math.max(max_width, vim.fn.strdisplaywidth(l))
			end

			for i, units in ipairs(content) do
				local only_header = #units > 0
				for _, u in ipairs(units) do
					if u.type ~= "header" then only_header = false end
				end
				if only_header then
					local pad = math.floor((max_width - vim.fn.strdisplaywidth(lines[i])) / 2)
					if pad > 0 then
						table.insert(units, 1, { string = string.rep(" ", pad), type = "header" })
					end
				end
			end

			return content
		end

		starter.setup({
			evaluate_single = true,

			header = clock,

			items = {
				{
					{
						name = "Dir last",
						action = function() require("persistence").load() end,
						section = "Sessions",
					},
					{
						name = "Last",
						action = function() require("persistence").load({ last = true }) end,
						section = "Sessions",
					},
					{
						name = "Choose",
						action = function() require("persistence").select() end,
						section = "Sessions",
					},
				},
				starter.sections.recent_files(10, true),
				starter.sections.recent_files(10, false),
				starter.sections.builtin_actions(),
			},

			content_hooks = {
				starter.gen_hook.adding_bullet("░ "),
				center_header,
				starter.gen_hook.padding(3, 2),
				starter.gen_hook.aligning("center", "center"),
			},

			footer = function()
				local ok, lazy = pcall(require, "lazy")
				if not ok then
					return ""
				end
				local stats = lazy.stats()
				return string.format("⚡ %d plugins  •  %.0f ms", stats.loaded, stats.startuptime)
			end,
		})

		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				-- nvim ouvert sur un fichier : pas de buffer Starter à rafraîchir
				if vim.bo.filetype == "ministarter" then
					starter.refresh()
				end
			end,
		})
	end,
}
