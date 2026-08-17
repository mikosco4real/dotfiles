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

M.mason = {
    pkgs = {
        "tailwindcss-language-server",
    },
}

return M
