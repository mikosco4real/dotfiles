-- Ported from lua/configs/conform.lua in the old config.

require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        css = { "prettierd" },
        html = { "prettierd" },
        vue = { "prettierd", lsp_format = "fallback" },
        ts = { "prettierd", "eslint_d" },
        json = { "jd" },
        sql = { "sqruff" },
    },

    format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
    },
})
