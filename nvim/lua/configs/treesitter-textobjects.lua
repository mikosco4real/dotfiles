-- nvim-treesitter-textobjects, `main` branch.
--
-- The main-branch rewrite dropped the declarative `textobjects = { select = {
-- keymaps = ... } }` block that the master branch had — setup() only takes
-- behaviour options now, and every mapping is registered by hand against the
-- module API. Queries come from the plugin's own queries/ directory.

require("nvim-treesitter-textobjects").setup({
    select = {
        -- Jump forward to the next textobject when the cursor is not inside one.
        lookahead = true,
    },
    move = {
        set_jumps = true,
    },
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

local objects = {
    f = { query = "@function.outer", inner = "@function.inner", desc = "function" },
    c = { query = "@class.outer", inner = "@class.inner", desc = "class" },
    a = { query = "@parameter.outer", inner = "@parameter.inner", desc = "argument" },
    o = { query = "@conditional.outer", inner = "@conditional.inner", desc = "conditional" },
    l = { query = "@loop.outer", inner = "@loop.inner", desc = "loop" },
}

for key, obj in pairs(objects) do
    vim.keymap.set({ "x", "o" }, "a" .. key, function()
        select.select_textobject(obj.query, "textobjects")
    end, { desc = "around " .. obj.desc })

    vim.keymap.set({ "x", "o" }, "i" .. key, function()
        select.select_textobject(obj.inner, "textobjects")
    end, { desc = "inside " .. obj.desc })
end

-- ]f / [f next / prev function start, ]F / [F their ends.
--
-- Function only, deliberately: the obvious key for class movement is ]c / [c,
-- which is vim's built-in diff-hunk motion and is what diffview and gitsigns
-- rely on inside a diff. Shadowing it would break both.
vim.keymap.set({ "n", "x", "o" }, "]f", function()
    move.goto_next_start("@function.outer", "textobjects")
end, { desc = "next function start" })

vim.keymap.set({ "n", "x", "o" }, "[f", function()
    move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "prev function start" })

vim.keymap.set({ "n", "x", "o" }, "]F", function()
    move.goto_next_end("@function.outer", "textobjects")
end, { desc = "next function end" })

vim.keymap.set({ "n", "x", "o" }, "[F", function()
    move.goto_previous_end("@function.outer", "textobjects")
end, { desc = "prev function end" })
