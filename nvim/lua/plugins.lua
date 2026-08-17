-- Install / load all plugins via the built-in vim.pack manager (nvim 0.12+).
-- vim.pack clones missing plugins synchronously, so any require() that
-- follows can immediately resolve them.
--
-- Note: unlike lazy.nvim, vim.pack has no event/cmd/keys lazy loading and
-- no `build` hooks. Anything that previously ran in a build step is wired
-- up explicitly after vim.pack.add() returns (see init.lua).

vim.pack.add({
    -- ── NvChad colour + UI stack (statusline, tabufline, term, themes…) ─
    { src = "https://github.com/NvChad/base46", version = "v3.0" },
    { src = "https://github.com/NvChad/ui", version = "v3.0" },
    { src = "https://github.com/nvzone/volt" },
    { src = "https://github.com/nvzone/menu" },
    { src = "https://github.com/nvzone/minty" },

    -- ── Core libraries ──────────────────────────────────────────────────
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },

    -- ── Editing helpers ─────────────────────────────────────────────────
    { src = "https://github.com/folke/which-key.nvim" },
    { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
    { src = "https://github.com/windwp/nvim-autopairs" },
    { src = "https://github.com/lewis6991/gitsigns.nvim" },

    -- ── File nav / picker ───────────────────────────────────────────────
    { src = "https://github.com/nvim-tree/nvim-tree.lua" },
    { src = "https://github.com/nvim-telescope/telescope.nvim" },

    -- ── Treesitter ──────────────────────────────────────────────────────
    -- Use `main` branch (the rewrite that targets nvim 0.11+ APIs). The old
    -- `master` branch has known injection-query breakage on nvim 0.12 — this
    -- is the root cause of the "weird treesitter errors" you saw on NvChad.
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },

    -- ── LSP + Mason ─────────────────────────────────────────────────────
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },

    -- ── Completion + snippets ───────────────────────────────────────────
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
    { src = "https://github.com/hrsh7th/cmp-nvim-lua" },
    { src = "https://github.com/hrsh7th/cmp-buffer" },
    { src = "https://codeberg.org/FelipeLema/cmp-async-path" },
    { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },

    -- ── Formatter ───────────────────────────────────────────────────────
    { src = "https://github.com/stevearc/conform.nvim" },

    -- ── Filetype-specific ──────────────────────────────────────────────
    { src = "https://github.com/luckasRanarison/tailwind-tools.nvim" },
})
