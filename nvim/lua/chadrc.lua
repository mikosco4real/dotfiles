-- Read by NvChad's `ui` plugin via `pcall(require, "chadrc")`.
-- Same structure as ~/.local/share/nvim/lazy/ui/lua/nvconfig.lua — only the
-- fields you want to override need to appear here.

---@type ChadrcConfig
local M = {}

M.base46 = {
    theme = "chadracula-evondev",

    -- hl_override = {
    --     Comment = { italic = true },
    --     ["@comment"] = { italic = true },
    -- },
}

-- nvchad.mason.get_pkgs() derives most packages from the enabled LSP servers and
-- the conform formatter list, but only for tools present in its own name map
-- (nvchad/mason/names.lua). sqruff, yamlfmt and postgres_lsp are not in it, so
-- they have to be named here or the bootstrap script silently skips them.
M.mason = {
    pkgs = {
        "tailwindcss-language-server",
        "yamlfmt",
        "taplo",
        "sqruff",
        "postgres-language-server",
        "prettierd",
    },
}

return M
