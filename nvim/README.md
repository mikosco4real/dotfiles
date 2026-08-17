# nvim-new

A fresh Neovim config that drops the NvChad meta-framework but keeps the
NvChad **look** (chadracula-evondev theme, statusline, tabufline, etc.)
and **keymaps**. Built for Neovim 0.12+ using the built-in `vim.pack`
package manager.

## What changed vs. the old setup

| Old (NvChad v2.5 framework) | New (this dir) |
| --- | --- |
| `lazy.nvim` plugin manager | Built-in `vim.pack` (nvim 0.12+) |
| `NvChad` core plugin (mappings/options/autocmds) | Local `lua/{keymaps,options,autocmds}.lua` |
| Implicit treesitter highlighting via NvChad hook | Explicit `require("nvim-treesitter.configs").setup{}` |
| `require("nvchad.configs.lspconfig").defaults()` | Direct `vim.lsp.config()` + `vim.lsp.enable()` |

Kept verbatim from NvChad (so the look + functionality survives):

- `nvchad/base46` (theme engine + chadracula-evondev colours)
- `nvchad/ui` (statusline, tabufline, term, themes picker, cheatsheet,
  `:MasonInstallAll`, `:Nvdash`, `:NvCheatsheet`, signature help)
- `nvzone/volt`, `nvzone/menu`, `nvzone/minty`
- `lua/chadrc.lua` (theme + mason package list)

## Prerequisites

- **Neovim 0.12+**
- **tree-sitter CLI** on PATH — required by the new nvim-treesitter `main`
  branch to compile parsers. Install with:

  ```bash
  brew install tree-sitter-cli
  ```

  Without it, parser installs fail and you fall back to vim's regex syntax
  highlighting.

## First-run instructions

```bash
# Launch with the alternate config dir — your current ~/.config/nvim is
# untouched. vim.pack will clone all plugins into ~/.local/share/nvim-new/
# on first start (synchronous, you'll see progress).
NVIM_APPNAME=nvim-new nvim

# In nvim, once plugins are installed:
:MasonInstallAll      " installs LSPs / formatters from chadrc + auto-detect
:checkhealth          " sanity check
```

Treesitter parsers from `lua/configs/treesitter.lua` install in the
background via `require("nvim-treesitter").install(...)`. To add new
parsers later: `:TSInstall <language>`.

## Daily commands

- `:Pack update` — update all plugins (replaces `:Lazy sync`)
- `:Pack` — list installed plugins
- `:Mason` — manage LSPs / formatters
- `:BuildHighlights` — regenerate the base46 cache after changing the
  theme in `lua/chadrc.lua` (then restart nvim)

## Layout

```
~/.config/nvim-new/
├── init.lua                  -- bootstrap, load order
├── lua/
│   ├── chadrc.lua            -- theme + mason packages (NvChad-style)
│   ├── options.lua           -- vim options
│   ├── keymaps.lua           -- full NvChad keymap set + personal overrides
│   ├── autocmds.lua          -- FilePost user event + treesitter start
│   ├── plugins.lua           -- vim.pack.add(...) + per-plugin requires
│   ├── lsp.lua               -- vim.lsp.config + vim.lsp.enable
│   └── configs/
│       ├── devicons.lua
│       ├── which-key.lua
│       ├── indent-blankline.lua
│       ├── gitsigns.lua
│       ├── nvim-tree.lua
│       ├── telescope.lua
│       ├── treesitter.lua
│       ├── mason.lua
│       ├── luasnip.lua
│       ├── cmp.lua
│       ├── autopairs.lua
│       ├── conform.lua
│       └── tailwind-tools.lua
└── README.md                 -- this file
```

## Promoting to the main config

When you've tested enough and want to swap:

```bash
# Back up the old config + data (safety first)
mv ~/.config/nvim ~/.config/nvim.nvchad-backup
mv ~/.local/share/nvim ~/.local/share/nvim.nvchad-backup

# Swap nvim-new into place
mv ~/.config/nvim-new ~/.config/nvim
mv ~/.local/share/nvim-new ~/.local/share/nvim
```

**Gotcha — fix treesitter query symlinks after the data-dir rename.**
`nvim-treesitter` (main branch) installs queries by symlinking each
language's query dir under `~/.local/share/nvim/site/queries/<lang>` to
the plugin's bundled `runtime/queries/<lang>`. Those symlinks store the
**original absolute path** (`…/nvim-new/site/pack/…`), so after the
`mv` they're all broken — parsers load but find no `highlights.scm`,
which manifests as **LSP working but zero syntax highlighting** (all
text is white). Repair in one shot:

```bash
src=~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/runtime/queries
dst=~/.local/share/nvim/site/queries
cd "$dst"
for link in $(find . -maxdepth 1 -type l ! -exec test -e {} \; -print); do
    name="${link#./}"
    rm "$link" && ln -s "$src/$name" "$name"
done
```

Re-run after future `:TSInstall` rounds if you ever rename the data dir
again. (Confirm none remain with the same `find … ! -exec test -e {} \;`
check.)

Your dotfiles `~/.dotfiles/nvim/.config/nvim` symlink is unaffected by
the side-by-side test — the new config lives entirely under
`~/.config/nvim-new` while you evaluate it.

## Known migration notes

- `vim.pack` has **no lazy-loading** by event/cmd/key, so startup will
  be slightly slower than with lazy.nvim. For a personal config this is
  usually negligible (<150ms cold start in my testing).
- `nvim-treesitter` is pinned to the **`main`** branch — the rewrite
  that targets nvim 0.11+ APIs. The old `master` branch has known
  injection-query breakage on nvim 0.12 (the source of the "weird
  treesitter errors" you saw on NvChad). The new branch requires the
  `tree-sitter` CLI to compile parsers (see Prerequisites above).
- `:MasonInstallAll` is provided by the NvChad `ui` plugin (loaded via
  `require("nvchad")` in `init.lua`) so the auto-install behaviour from
  the old config still works.
