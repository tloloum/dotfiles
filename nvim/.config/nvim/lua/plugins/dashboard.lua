return {
  "echasnovski/mini.starter",
  version = false,
  config = function()
    local starter = require("mini.starter")

    -- Bannière ASCII
    local banner = table.concat({
      "",
      "  ███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗ ",
      "  ████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║ ",
      "  ██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║ ",
      "  ██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║ ",
      "  ██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝ ",
      "",
    }, "\n")

    starter.setup({
      evaluate_single = true,

      -- En-tête : bannière + salutation selon l'heure
      header = function()
        local hour = tonumber(os.date("%H"))
        local greeting = (hour < 12 and "Bonjour")
          or (hour < 18 and "Bon après-midi")
          or "Bonsoir"
        return banner .. "\n " .. greeting .. ", tof"
      end,

      items = {
        {
          {
            name = "Reprendre la session (dossier courant)",
            action = function() require("persistence").load() end,
            section = "Sessions",
          },
          {
            name = "Reprendre la dernière session",
            action = function() require("persistence").load({ last = true }) end,
            section = "Sessions",
          },
          {
            name = "Choisir une session",
            action = function() require("persistence").select() end,
            section = "Sessions",
          },
        },
        starter.sections.recent_files(10, true),  -- fichiers récents du dossier courant
        starter.sections.recent_files(10, false), -- fichiers récents (globaux)
        starter.sections.builtin_actions(),       -- nouveau fichier / quitter
      },

      content_hooks = {
        starter.gen_hook.adding_bullet("░ "),          -- puce devant chaque item
        starter.gen_hook.padding(3, 2),                -- marge gauche/haut
        starter.gen_hook.aligning("center", "center"), -- tout centré
        -- pas de gen_hook.indexing : pas de chiffres, on tape pour filtrer les noms
      },

      -- Pied de page : nombre de plugins + temps de démarrage
      footer = function()
        local ok, lazy = pcall(require, "lazy")
        if not ok then
          return ""
        end
        local stats = lazy.stats()
        return string.format("⚡ %d plugins  •  %.0f ms", stats.loaded, stats.startuptime)
      end,
    })

    -- Rafraîchit le footer une fois le démarrage terminé (pour un temps correct)
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        pcall(starter.refresh)
      end,
    })
  end,
}
