-- In-buffer rendering for markdown: headings, callouts, checkboxes, tables.
-- Only renders visible lines and stays rendered while editing, and the file on
-- disk stays plain markdown.
--
-- This is the single renderer for markdown buffers — obsidian.nvim's own UI is
-- disabled in configs/obsidian.lua precisely so these two don't fight.

require("render-markdown").setup({
    file_types = { "markdown" },
    completions = { lsp = { enabled = true } },

    heading = {
        sign = false,
        width = "block",
        left_pad = 0,
        right_pad = 2,
    },

    code = {
        sign = false,
        width = "block",
        right_pad = 2,
    },

    checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
        -- Mirrors the Obsidian Tasks emoji signifiers already used in the vault
        -- (e.g. "- [x] … 🛫 2025-06-02 📅 2025-06-02 ✅ 2025-06-02").
        custom = {
            todo = { raw = "[>]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
            cancelled = { raw = "[-]", rendered = "󰅘 ", highlight = "RenderMarkdownError" },
        },
    },

    -- Obsidian-style callouts (> [!note], > [!warning], …) render natively.
    pipe_table = { preset = "round" },
})
