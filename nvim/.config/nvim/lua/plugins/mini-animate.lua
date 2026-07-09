return {
  "echasnovski/mini.animate",
  event = "VeryLazy", -- chargé une fois l'UI prête
  config = function()
    local animate = require("mini.animate")
    animate.setup({
      -- Défilement animé (Ctrl-d / Ctrl-u / gg / G / zz ...)
      scroll = {
        enable = true,
        timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
      },
      -- Curseur qui glisse d'une position à l'autre
      cursor = {
        enable = true,
        timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
      },
      -- Redimensionnement animé des fenêtres
      resize = {
        enable = true,
        timing = animate.gen_timing.quadratic({ duration = 100, unit = "total" }),
      },
      -- Fondu à l'ouverture / fermeture des fenêtres flottantes
      open = { enable = true },
      close = { enable = true },
    })
  end,
}
