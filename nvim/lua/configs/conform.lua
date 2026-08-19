-- Formatting policy.
--
-- format_on_save runs CLI formatters only. For the data/markup filetypes listed
-- in `no_lsp_format` below, LSP formatting is *banned*, because the servers that
-- offer it are Prettier-backed and rewrite the whole document:
--
--   yaml-language-server implements textDocument/formatting by calling bundled
--   Prettier. Prettier parses `{{ x }}` as a nested YAML flow mapping — legal
--   YAML, so no parse error is raised and its own catch never fires — then
--   re-emits it as `{ { x } }`, applying bracketSpacing at both brace levels.
--   That silently corrupts every Tera / Jinja / Helm / Go template on save.
--   nvim-lspconfig makes it worse by force-setting documentFormattingProvider =
--   true in its yamlls on_init, so conform's has_lsp_formatter() check cannot be
--   trusted. See the matching yamlls override in lua/lsp.lua.
--
-- Every other filetype keeps lsp_format = "fallback", so rustfmt / gofmt /
-- phpactor still format on save. A blanket "never" would silently regress those.

local conform = require("conform")

-- LSP formatting is never allowed for these. Only the CLI formatters in
-- formatters_by_ft may touch them.
local no_lsp_format = {
    yaml = true,
    json = true,
    jsonc = true,
    toml = true,
    markdown = true,
    html = true,
    xml = true,
}

-- Filetypes checked for template markers before formatting. Deliberately scoped
-- to data and markup: `{{` is ordinary syntax in Rust, Go, JS and Lua source, so
-- guarding those would disable formatting for no reason.
local guarded_filetypes = {
    yaml = true,
    json = true,
    jsonc = true,
    toml = true,
    sql = true,
    html = true,
    xml = true,
    markdown = true,
    css = true,
    scss = true,
}

-- Tera / Jinja / Liquid / Handlebars / Go templates, and ERB / EJS. No
-- general-purpose formatter understands any of them and all of them corrupt the
-- file, so a buffer containing one is never formatted automatically.
local markers = { "{{", "{%", "<%" }

--- Locate the first template marker in a buffer.
--- Returns nil for unguarded filetypes and for buffers with no markers.
---@param bufnr integer
---@return string|nil marker, integer|nil lnum 1-indexed line number
local function find_template_marker(bufnr)
    if not guarded_filetypes[vim.bo[bufnr].filetype] then
        return nil
    end

    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        for _, marker in ipairs(markers) do
            if line:find(marker, 1, true) then
                return marker, lnum
            end
        end
    end

    return nil
end

--- Why format-on-save would skip this buffer, or nil if it would run.
---@param bufnr integer
---@return string|nil
local function skip_reason(bufnr)
    if vim.g.disable_autoformat then
        return "format-on-save is disabled globally (:FormatEnable to re-enable)"
    end

    if vim.b[bufnr].disable_autoformat then
        return "format-on-save is disabled for this buffer (:FormatEnable to re-enable)"
    end

    local marker, lnum = find_template_marker(bufnr)
    if marker then
        return ("template marker %q found on line %d — formatting would corrupt it"):format(marker, lnum)
    end

    return nil
end

conform.setup({
    formatters_by_ft = {
        lua = { "stylua" },

        -- yamlfmt, not prettierd: it normalises indentation and line breaks and
        -- leaves quoting and flow style alone. Prettier rewrites both, which
        -- churns shared project YAML.
        yaml = { "yamlfmt" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        toml = { "taplo" },
        sql = { "sqruff" },

        css = { "prettierd" },
        scss = { "prettierd" },
        html = { "prettierd" },
        markdown = { "prettierd" },
        vue = { "prettierd" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
    },

    default_format_opts = { lsp_format = "fallback" },

    format_on_save = function(bufnr)
        if skip_reason(bufnr) then
            return nil
        end

        return {
            timeout_ms = 1000,
            lsp_format = no_lsp_format[vim.bo[bufnr].filetype] and "never" or "fallback",
        }
    end,
})

-- ── Escape hatches ──────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        vim.b.disable_autoformat = true
        vim.notify("format-on-save disabled for this buffer", vim.log.levels.INFO)
    else
        vim.g.disable_autoformat = true
        vim.notify("format-on-save disabled globally", vim.log.levels.INFO)
    end
end, { desc = "Disable format-on-save (! for current buffer only)", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
    vim.notify("format-on-save enabled", vim.log.levels.INFO)
end, { desc = "Re-enable format-on-save" })

vim.api.nvim_create_user_command("FormatInfo", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local reason = skip_reason(bufnr)

    if reason then
        vim.notify("format-on-save SKIPPED: " .. reason, vim.log.levels.WARN)
        return
    end

    local names = vim.tbl_map(function(f)
        return f.name
    end, conform.list_formatters(bufnr))

    if #names == 0 then
        local via = no_lsp_format[vim.bo[bufnr].filetype] and "nothing (LSP formatting is banned here)" or "the LSP"
        vim.notify("format-on-save runs via " .. via, vim.log.levels.INFO)
    else
        vim.notify("format-on-save runs: " .. table.concat(names, ", "), vim.log.levels.INFO)
    end
end, { desc = "Explain what format-on-save will do to this buffer" })

-- Manual format. Respects the template guard so a stray <leader>fm cannot break
-- a template either; `:Format!` forces it through.
vim.api.nvim_create_user_command("Format", function(args)
    local bufnr = vim.api.nvim_get_current_buf()

    if not args.bang then
        local marker, lnum = find_template_marker(bufnr)
        if marker then
            vim.notify(
                ("Refusing to format: template marker %q on line %d. Use :Format! to override."):format(marker, lnum),
                vim.log.levels.WARN
            )
            return
        end
    end

    local range = nil
    if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(bufnr, args.line2 - 1, args.line2, true)[1]
        range = { start = { args.line1, 0 }, ["end"] = { args.line2, end_line:len() } }
    end

    conform.format({ async = true, lsp_format = "fallback", range = range })
end, { desc = "Format buffer or range (! ignores the template guard)", bang = true, range = true })
