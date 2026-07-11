vim.g.mapleader = " "

local keymap = vim.keymap.set

keymap("x", "<S-k>", ":move '<-2<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le haut en mode visuel bloc" })

keymap("x", "<S-j>", ":move '>+1<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le bas en mode visuel bloc" })

keymap("n", "<C-h>", "<C-w>h", { desc = "Déplace le curseur dans la fenêtre de gauche" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Déplace le curseur dans la fenêtre du bas" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Déplace le curseur dans la fenêtre du haut" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Déplace le curseur dans la fenêtre droite" })

keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap("n", "<leader>q", ":bdelete<CR>", opts)

keymap("n", "<leader>q!", ":bdelete!<CR>", opts)
keymap("n", "<leader>qq", ":q!<CR>", opts)
keymap("n", "<leader>wqa", ":wqa<CR>", opts)
keymap("n", "<leader>wq", ":wq<CR>", opt)
keymap("n", "<leader>wa", ":wa<CR>", opts)
keymap("n", "<leader>ww", ":w<CR>", opts)
