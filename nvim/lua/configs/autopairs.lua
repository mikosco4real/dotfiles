require("nvim-autopairs").setup({
    fast_wrap = {},
    disable_filetype = { "TelescopePrompt", "vim" },
})

-- Wire autopairs into cmp's confirm action so `(` etc. close on completion.
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
