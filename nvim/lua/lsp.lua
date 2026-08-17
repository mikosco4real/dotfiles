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
})
