-- Diagnostics / quickfix / loclist / symbols in one pane.
--
-- Note the keymaps are under <leader>d, not the upstream <leader>x: <leader>x is
-- already "close buffer" in this config (lua/keymaps.lua).
require("trouble").setup({
    focus = true,
    warn_no_results = false,
    open_no_results = true,
})
