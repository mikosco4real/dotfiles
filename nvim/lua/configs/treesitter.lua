-- nvim-treesitter `main` branch setup. The new API drops
-- `require('nvim-treesitter.configs').setup()` — parsers are installed
-- explicitly via `require('nvim-treesitter').install(...)`, and the
-- FileType autocmd in lua/autocmds.lua calls `vim.treesitter.start()`
-- per buffer to actually enable highlighting.

pcall(function()
    dofile(vim.g.base46_cache .. "syntax")
    dofile(vim.g.base46_cache .. "treesitter")
end)

local parsers = {
    "lua",
    "luadoc",
    "vim",
    "vimdoc",
    "python",
    "rust",
    "go",
    "printf",
    "javascript",
    "bash",
    "css",
    "json",
    "html",
    "markdown",
    "markdown_inline",
    "nginx",
    "php",
    "sql",
    "tmux",
    "tsx",
    "typescript",
    "vue",
    "yaml",
    "toml",
}

-- install() is async: missing parsers download + compile in the background.
require("nvim-treesitter").install(parsers)

-- Treesitter-based indent (opt-in per filetype since main branch dropped
-- the global `indent.enable = true` switch).
vim.api.nvim_create_autocmd("FileType", {
    pattern = parsers,
    callback = function(args)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
