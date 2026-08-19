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

- `:lua vim.pack.update()` — update all plugins (replaces `:Lazy sync`).
  **`:Pack` does not exist** — `vim.pack` is a Lua API, not an ex command.
- `:lua =vim.pack.get()` — list installed plugins
- `:Mason` — manage LSPs / formatters
- `:BuildHighlights` — regenerate the base46 cache after changing the
  theme in `lua/chadrc.lua` (then restart nvim)
- `:ConformInfo` — which formatter will run on this buffer, and whether
  its binary was found
- `:FormatInfo` — whether format-on-save will run here, and why not if not

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
│       ├── conform.lua           -- formatting policy (see below)
│       ├── diffview.lua
│       ├── gitlinker.lua
│       ├── surround.lua
│       ├── todo-comments.lua
│       ├── treesitter-textobjects.lua
│       ├── trouble.lua
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

- `vim.pack` has **no lazy-loading** by event/cmd/key, so every plugin loads
  at startup. Measured cold start is ~170ms, of which the git and editing
  plugins added later (diffview, gitlinker, surround, todo-comments, trouble,
  treesitter-textobjects) account for ~22ms combined. The two biggest single
  costs are pre-existing: luasnip ~24ms and telescope ~20ms. Re-measure with
  `nvim --headless --startuptime /tmp/st.log +qa`.
- `nvim-treesitter` is pinned to the **`main`** branch — the rewrite
  that targets nvim 0.11+ APIs. The old `master` branch has known
  injection-query breakage on nvim 0.12 (the source of the "weird
  treesitter errors" you saw on NvChad). The new branch requires the
  `tree-sitter` CLI to compile parsers (see Prerequisites above).
- `:MasonInstallAll` is provided by the NvChad `ui` plugin (loaded via
  `require("nvchad")` in `init.lua`) so the auto-install behaviour from
  the old config still works.

## Formatting policy

`format_on_save` runs **CLI formatters only** for data and markup filetypes.
LSP formatting is banned for `yaml`, `json`, `jsonc`, `toml`, `markdown`,
`html` and `xml`; every other filetype keeps `lsp_format = "fallback"`, so
rustfmt / gofmt / phpactor still run on save.

The reason is specific and was reproduced before the fix went in:

> `yaml-language-server` implements `textDocument/formatting` by calling
> **bundled Prettier**. Prettier parses `{{ get_env(name="X") }}` as a nested
> YAML *flow mapping* — which is legal YAML, so nothing throws and the
> server's own `catch` never fires — and re-emits it as
> `{ { get_env(name="X") } }`, applying `bracketSpacing` at both brace levels.
> It replaces the whole document, so one save corrupts every template in the
> file. Measured on `webtize_ai_backend_rs/config/development.yaml`: 16
> corrupted expressions per save.
>
> `nvim-lspconfig` compounds it. Its `lsp/yamlls.lua` sets
> `yaml.format.enable = true` *and* force-sets
> `documentFormattingProvider = true` in `on_init` — so clearing the setting
> alone is not enough, and conform's `has_lsp_formatter()` check cannot be
> trusted. `lua/lsp.lua` overrides both.

On top of that, **any** buffer in a guarded filetype containing `{{`, `{%` or
`<%` is skipped entirely, by `find_template_marker()` in
`lua/configs/conform.lua`. The guard is scoped to data and markup filetypes on
purpose: `{{` is ordinary syntax in Rust, Go, JS and Lua, and guarding those
would disable formatting for no reason.

Escape hatches:

| Command | Effect |
| --- | --- |
| `:FormatInfo` | Explain what will happen to this buffer, naming the marker and line if it is being skipped |
| `:FormatDisable` | Turn format-on-save off globally |
| `:FormatDisable!` | Turn it off for the current buffer only |
| `:FormatEnable` | Turn it back on |
| `:Format` | Format now (respects the template guard); takes a range |
| `:Format!` | Format now, ignoring the guard |

Formatters by filetype: `stylua` (lua), `yamlfmt` (yaml), `taplo` (toml),
`sqruff` (sql), `prettierd` (json, jsonc, css, scss, html, markdown, vue,
javascript, typescript and their react variants).

`yamlfmt` rather than `prettierd` for YAML deliberately: it normalises
indentation and line breaks but leaves quoting and flow style alone, where
Prettier rewrites both and churns shared project files.

## Data-file language servers

| Filetype | Server | Notes |
| --- | --- | --- |
| yaml | `yamlls` | Schemas from SchemaStore.nvim (~1300). Formatter hard-disabled; `keyOrdering` off. |
| json | `jsonls` | Schemas from SchemaStore.nvim (~1400), validation on. |
| toml | `taplo` | |
| sql | `postgres_lsp` | **Dormant by default** — see below. |

`postgres_lsp` declares `workspace_required = true` with a single root marker,
so it only attaches in a project that carries a `postgres-language-server.jsonc`
at its root:

```jsonc
{
  "db": { "host": "127.0.0.1", "port": 5432, "user": "postgres", "database": "mydb" },
  "files": { "ignore": ["node_modules"] }
}
```

Without that file nothing attaches and nothing breaks — SQL still gets
`sqruff` formatting on save. `sqruff` defaults to the ANSI dialect; add a
`.sqruff` with `dialect = postgres` per project when its output looks off.

## Git

`gitsigns` handles hunks, line blame and full-file blame. `diffview.nvim` adds
revision-range diffs, file history and a three-way merge tool. `lazygit` runs
in a float via `nvchad.term`'s `cmd` option — no plugin involved.

Hunk bindings are **buffer-local** (registered in gitsigns' `on_attach`), so
they only exist inside a repo.

| Key | Action |
| --- | --- |
| `]h` / `[h` | Next / previous hunk (falls back to `]c` / `[c` inside a diff) |
| `<leader>hs` / `<leader>hr` | Stage / reset hunk — also works on a visual selection |
| `<leader>hS` / `<leader>hR` | Stage / reset whole buffer |
| `<leader>hu` | Undo stage hunk |
| `<leader>hp` / `<leader>hi` | Preview hunk in a float / inline |
| `<leader>hd` / `<leader>hD` | Diff against index / against last commit |
| `<leader>hq` / `<leader>hQ` | Hunks to quickfix — this buffer / whole repo |
| `ih` | Hunk text object (`vih`, `dih`, `cih`) |

| Key | Action |
| --- | --- |
| `<leader>gg` | lazygit in a float (press again to dismiss) |
| `<leader>gb` | Blame current line — full commit in a popup |
| `<leader>gB` | Toggle inline blame virtual text |
| `<leader>gL` | Full-file blame window |
| `<leader>gs` / `<leader>gc` | Telescope git status / commits |
| `<leader>gd` / `<leader>gD` | Diffview: working tree / vs `origin/HEAD` |
| `<leader>gf` / `<leader>gF` | File history: this file / whole repo |
| `<leader>gx` | Close Diffview |
| `<leader>gy` / `<leader>gY` | Copy / open a remote permalink (works on a visual range) |

**`<leader>h` no longer opens a horizontal terminal** — it is the hunk prefix
now. A direct map there would swallow every `<leader>h*` binding for
`timeoutlen` (400ms). The terminal moved to `<leader>tt`; `<leader>v` is
unchanged. `<leader>cm` and `<leader>gt` were retired in favour of
`<leader>gc` and `<leader>gs`.

## Other keymaps added

| Key | Action |
| --- | --- |
| `<leader>ca` | Code action (n and v) |
| `gr` / `gi` / `gs` | References / implementation / signature help |
| `<leader>dd` | Line diagnostics in a float |
| `<leader>dt` / `<leader>dT` | Trouble diagnostics — repo / buffer |
| `<leader>dq` / `<leader>dl` | Trouble quickfix / location list |
| `<leader>ft` | Telescope TODO comments |
| `]t` / `[t` | Next / previous TODO comment |
| `af` `if` `ac` `ic` `aa` `ia` `ao` `io` `al` `il` | Treesitter text objects: function, class, argument, conditional, loop |
| `]f` / `[f` / `]F` / `[F` | Next / previous function start / end |

Neovim 0.11+ already provides `K`, `grn`, `gra`, `grr`, `gri`, `grt`, `gO` and
`]d` / `[d` by default — the above sit alongside those rather than replacing
them.

Class movement is **not** bound to `]c` / `[c` on purpose: those are vim's
built-in diff-hunk motions, which gitsigns and diffview both rely on inside a
diff.
