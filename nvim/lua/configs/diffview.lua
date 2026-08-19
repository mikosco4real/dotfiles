-- Diffview covers the two things gitsigns cannot: reviewing a whole revision
-- range side by side, and browsing file/branch history. Keymaps live in
-- lua/keymaps.lua under <leader>g.

require("diffview").setup({
    enhanced_diff_hl = true,
    view = {
        -- Three-way merge tool for conflicts; `merge_tool` is what :DiffviewOpen
        -- drops you into during a rebase or merge.
        merge_tool = {
            layout = "diff3_mixed",
            disable_diagnostics = true,
            winbar_info = true,
        },
        file_history = { winbar_info = true },
    },
    file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 32 },
    },
    keymaps = {
        -- `q` closes from anywhere in the view, matching the telescope config.
        view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "close diffview" } } },
        file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "close diffview" } } },
        file_history_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "close diffview" } } },
    },
})
