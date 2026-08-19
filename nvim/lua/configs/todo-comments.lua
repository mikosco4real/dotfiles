-- Highlights TODO / FIX / HACK / WARN / PERF / NOTE / TEST and makes them
-- searchable. `signs = false` because the sign column is already carrying
-- gitsigns and diagnostics.
require("todo-comments").setup({
    signs = false,
})
