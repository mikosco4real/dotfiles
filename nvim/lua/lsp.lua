-- LSP setup via the nvim 0.11+ API. `nvim-lspconfig` ships per-server
-- defaults at lsp/<server>.lua on the runtimepath, so vim.lsp.enable()
-- picks them up automatically — we only need to supply shared capabilities
-- + on_attach behaviour here.

dofile(vim.g.base46_cache .. "lsp")

-- Diagnostic UI (signs, virtual text, float border) matching the old NvChad look.
require("nvchad.lsp").diagnostic_config()

-- ── Capabilities: tell servers about completion features cmp supports ─────
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem = {
    documentationFormat = { "markdown", "plaintext" },
    snippetSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true,
    labelDetailsSupport = true,
    deprecatedSupport = true,
    commitCharactersSupport = true,
    tagSupport = { valueSet = { 1 } },
    resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" },
    },
}

local ok, cmp_caps = pcall(require, "cmp_nvim_lsp")
if ok then
    capabilities = vim.tbl_deep_extend("force", capabilities, cmp_caps.default_capabilities())
end

local function on_init(client, _)
    if client:supports_method("textDocument/semanticTokens") then
        client.server_capabilities.semanticTokensProvider = nil
    end
end

-- ── Per-buffer keymaps on attach (matches NvChad's bindings) ──────────────
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local function opts(desc)
            return { buffer = bufnr, desc = "LSP " .. desc }
        end

        local map = vim.keymap.set
        map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
        map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts("Add workspace folder"))
        map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))
        map("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts("List workspace folders"))
        map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
        map("n", "<leader>ra", require("nvchad.lsp.renamer"), opts("NvRenamer"))

        -- Ergonomic aliases. nvim 0.11+ already provides K, grn, gra, grr, gri,
        -- grt, gO and ]d / [d by default — these sit alongside those, they do
        -- not replace them.
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        map("n", "gr", vim.lsp.buf.references, opts("References"))
        map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
        map("n", "gs", vim.lsp.buf.signature_help, opts("Signature help"))
        map("n", "<leader>dd", vim.diagnostic.open_float, opts("Line diagnostics"))
    end,
})

-- ── Shared defaults + per-server overrides ────────────────────────────────
vim.lsp.config("*", { capabilities = capabilities, on_init = on_init })

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                library = {
                    vim.fn.expand("$VIMRUNTIME/lua"),
                    vim.fn.stdpath("data") .. "/site/pack/core/opt/ui/nvchad_types",
                    "${3rd}/luv/library",
                },
            },
        },
    },
})

-- yamlls: schemas on, formatter off — hard off.
--
-- nvim-lspconfig's lsp/yamlls.lua sets `yaml.format.enable = true` AND force-sets
-- documentFormattingProvider = true in its own on_init. yaml-language-server
-- implements that formatter with bundled Prettier, which parses `{{ x }}` as a
-- nested YAML flow mapping and re-emits it as `{ { x } }`, corrupting every
-- Tera / Jinja / Helm / Go template on save. Undoing the setting alone is not
-- enough; the forced capability has to go too.
--
-- Note this on_init *replaces* lspconfig's, which in turn shadows the one set on
-- "*" above — so call the shared on_init explicitly to keep the semantic-token
-- strip that every other server gets.
vim.lsp.config("yamlls", {
    on_init = function(client, result)
        on_init(client, result)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        yaml = {
            format = { enable = false },
            -- Alphabetising keys is a destructive "fix" for hand-written config.
            keyOrdering = false,
            -- SchemaStore.nvim supplies the catalogue; the server's own fetcher
            -- would race it and double up.
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
        },
    },
})

vim.lsp.config("jsonls", {
    settings = {
        json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
        },
    },
})

-- Enable everything the old config enabled, plus lua_ls.
vim.lsp.enable({
    "lua_ls",
    "html",
    "cssls",
    "phpactor",
    "pyright",
    "gopls",
    "vuels",
    "yamlls",
    "dockerls",
    "tailwindcss",
    "pasls",
    "nginx_language_server",
    "markdown_oxide",
    "ltex",
    "jsonls",
    "docker_compose_language_service",
    "rust_analyzer",
    "taplo",
    -- postgres_lsp declares workspace_required = true with a single root marker,
    -- so it stays dormant until a project carries a postgres-language-server.jsonc.
    "postgres_lsp",
})
