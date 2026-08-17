-- Same defaults NvChad shipped in nvchad/configs/telescope.lua.

dofile(vim.g.base46_cache .. "telescope")

local actions = require("telescope.actions")

require("telescope").setup({
    defaults = {
        prompt_prefix = "   ",
        selection_caret = " ",
        entry_prefix = " ",
        sorting_strategy = "ascending",
        layout_config = {
            horizontal = {
                prompt_position = "top",
                preview_width = 0.55,
            },
            width = 0.87,
            height = 0.80,
        },
        mappings = {
            n = { ["q"] = actions.close },
        },
    },
    extensions = {},
})

-- Extensions shipped by the NvChad `ui` plugin (themes picker, terms picker).
pcall(require("telescope").load_extension, "themes")
pcall(require("telescope").load_extension, "terms")
