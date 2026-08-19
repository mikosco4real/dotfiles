dofile(vim.g.base46_cache .. "git")

local gitsigns = require("gitsigns")

gitsigns.setup({
    signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "│" },
    },

    -- Distinct signs for staged hunks, so <leader>hs gives visible feedback.
    signs_staged_enable = true,

    -- Off by default — <leader>gB toggles it. Always-on virtual text is noisy
    -- and costs a git call per cursor rest.
    current_line_blame = false,
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
        ignore_whitespace = false,
    },
    current_line_blame_formatter = "  <author>, <author_time:%R> · <summary>",

    preview_config = { border = "rounded" },

    on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git " .. desc })
        end

        -- ── Navigation ──────────────────────────────────────────────────
        -- Jump even when the diff is stale/off-screen; falls back to the file
        -- start rather than erroring when there are no hunks.
        map("n", "]h", function()
            if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
            else
                gitsigns.nav_hunk("next")
            end
        end, "next hunk")

        map("n", "[h", function()
            if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
            else
                gitsigns.nav_hunk("prev")
            end
        end, "prev hunk")

        -- ── Stage / reset ───────────────────────────────────────────────
        map("n", "<leader>hs", gitsigns.stage_hunk, "stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "reset hunk")

        map("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "stage selection")

        map("v", "<leader>hr", function()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "reset selection")

        map("n", "<leader>hS", gitsigns.stage_buffer, "stage buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "reset buffer")
        map("n", "<leader>hu", gitsigns.undo_stage_hunk, "undo stage hunk")

        -- ── Inspect ─────────────────────────────────────────────────────
        map("n", "<leader>hp", gitsigns.preview_hunk, "preview hunk")
        map("n", "<leader>hi", gitsigns.preview_hunk_inline, "preview hunk inline")
        map("n", "<leader>hd", gitsigns.diffthis, "diff against index")
        map("n", "<leader>hD", function()
            gitsigns.diffthis("~")
        end, "diff against last commit")

        -- ── Quickfix ────────────────────────────────────────────────────
        map("n", "<leader>hq", function()
            gitsigns.setqflist("attached")
        end, "hunks to quickfix (buffer)")
        map("n", "<leader>hQ", function()
            gitsigns.setqflist("all")
        end, "hunks to quickfix (repo)")

        -- ── Text object: vih / dih / cih ────────────────────────────────
        map({ "o", "x" }, "ih", gitsigns.select_hunk, "select hunk")
    end,
})
