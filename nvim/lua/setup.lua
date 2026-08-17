-- Per-plugin setup. Runs after vim.pack.add() (so requires resolve) and
-- after the base46 highlight cache exists (so dofile() can read it).
--
-- Order matters: completion deps before cmp, mason before LSP.

require("configs.devicons")
require("configs.which-key")
require("configs.indent-blankline")
require("configs.gitsigns")
require("configs.nvim-tree")
require("configs.telescope")
require("configs.treesitter")
require("configs.mason")
require("configs.luasnip")
require("configs.cmp")
require("configs.autopairs")
require("configs.conform")
require("configs.tailwind-tools")
