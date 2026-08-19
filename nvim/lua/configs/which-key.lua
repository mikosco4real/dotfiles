dofile(vim.g.base46_cache .. "whichkey")

local wk = require("which-key")

wk.setup({})

-- Without these every prefix menu is an unlabelled list of keys.
wk.add({
    { "<leader>b", desc = "buffer new" },
    { "<leader>c", group = "code / cheatsheet" },
    { "<leader>d", group = "diagnostics" },
    { "<leader>f", group = "find / format" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "git hunk", mode = { "n", "v" } },
    { "<leader>t", group = "toggle / terminal" },
    { "<leader>w", group = "workspace / which-key" },
    { "[", group = "prev" },
    { "]", group = "next" },
})
