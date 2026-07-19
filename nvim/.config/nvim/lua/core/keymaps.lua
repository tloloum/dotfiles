vim.g.mapleader = " "

local keymap = vim.keymap.set

keymap("x", "<S-k>", ":move '<-2<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le haut en mode visuel bloc" })

keymap("x", "<S-j>", ":move '>+1<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le bas en mode visuel bloc" })

keymap("n", "<C-h>", "<C-w>h", { desc = "Move Left" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move Right" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move Up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move Down" })

keymap("n", "<leader>bsv", "<C-w>v", { desc = "Vertical" })
keymap("n", "<leader>bsh", "<C-w>s", { desc = "Horizontal" })
keymap("n", "<leader>bsq", "<C-w>c", { desc = "Close split" })
