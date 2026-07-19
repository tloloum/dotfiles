local opt = vim.opt

opt.relativenumber = true
opt.number = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = false
opt.autoindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

opt.cursorline = true

opt.termguicolors = true -- need for theme
opt.background = "dark"
opt.signcolumn = "no"

opt.backspace = "indent,eol,start"

opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false

opt.mousescroll = "ver:8,hor:8"

opt.undofile = true

opt.list = true
opt.listchars:append({ tab = "  ", nbsp = "␣", trail = "•", precedes = "«", extends = "»" })

