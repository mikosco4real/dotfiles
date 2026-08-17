-- Entry point for the post-NvChad migration config.
-- Launch side-by-side with:  NVIM_APPNAME=nvim-new nvim
-- See README.md for details.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"

-- Disable unused language providers (matches the old NvChad defaults).
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Step 1: install / load plugin paths via vim.pack (synchronous).
require("plugins")

-- Step 2: build the base46 highlight cache on first run (or when missing).
-- Must happen AFTER vim.pack.add() puts base46 on the rtp and BEFORE any
-- plugin config does `dofile(vim.g.base46_cache .. "...")`.
local cache = vim.g.base46_cache
if not vim.uv.fs_stat(cache) or not vim.uv.fs_stat(cache .. "defaults") then
    vim.fn.mkdir(cache, "p")
    require("base46").load_all_highlights()
end

-- Step 3: apply the cached highlights (theme + statusline).
dofile(cache .. "defaults")
dofile(cache .. "statusline")

-- Step 4: configure each plugin (reads from the base46 cache).
require("setup")

-- Step 5: initialise the NvChad UI plugin (statusline / tabufline / term
-- / :MasonInstallAll / :NvCheatsheet / signature help, etc.).
require("nvchad")

require("options")
require("autocmds")
require("lsp")

vim.schedule(function()
    require("keymaps")
end)

vim.api.nvim_create_user_command("BuildHighlights", function()
    require("base46").load_all_highlights()
    vim.notify("base46 highlight cache rebuilt — restart nvim", vim.log.levels.INFO)
end, { desc = "Regenerate base46 highlight cache" })
