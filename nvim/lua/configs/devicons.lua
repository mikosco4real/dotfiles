-- Apply base46-themed devicon highlights, then override with NvChad's
-- icon glyph set so file-type icons in nvim-tree / telescope / bufferline
-- look identical to the previous NvChad config.

dofile(vim.g.base46_cache .. "devicons")

require("nvim-web-devicons").setup({
    override = require("nvchad.icons.devicons"),
})
