-- Permalinks to the current line / selection on the remote host.
--
-- Keymaps use the `:GitLink` user command rather than the Lua API: the command
-- takes a range directly, so visual-mode selections work without threading line
-- numbers by hand. `:GitLink` copies, `:GitLink!` opens a browser.

-- The plugin ships no default keymaps; ours are in lua/keymaps.lua.
require("gitlinker").setup({
    -- The generated URL already lands on the clipboard; echoing it as well just
    -- triggers a press-enter prompt.
    message = false,
})
