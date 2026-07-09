vim.g.mapleadere = " " 

local keymap = vim.keymap.set

keymap("x", "<S-k>", ":move '<-2<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le haut en mode visuel bloc" })

keymap("x", "<S-j>", ":move '>+1<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le bas en mode visuel bloc" })
