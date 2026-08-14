# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles managed with **GNU Stow**. There is no build step and no test suite — edits to files in this repo take effect on the host the moment Stow's symlinks are in place.

## Stow layout

Each top-level directory is a Stow *package*. Its contents mirror `$HOME`, so running `stow <pkg>` from this directory symlinks the files into the correct location.

```
~/.dotfiles/<pkg>/<relative-path-under-HOME>  →  ~/<relative-path-under-HOME>
```

Examples:
- `zshrc/.zshrc` → `~/.zshrc`
- `nvim/.config/nvim/init.lua` → `~/.config/nvim/init.lua`
- `tmux/.tmux.conf` → `~/.tmux.conf`

Common commands (run from `~/.dotfiles`):
- `stow <pkg>` — link a package into `$HOME`
- `stow -R <pkg>` — re-stow after adding/removing files
- `stow -D <pkg>` — unlink
- `stow -nv <pkg>` — dry run; prints what *would* change. This is the closest thing to a test suite here — use it to verify a layout change before touching `$HOME`.

**Re-stowing is rarely needed.** Stow *folds* directories: `~/.config/nvim` and `~/.tmux/scripts` are single symlinks to their repo directories, so editing an existing file **and adding a new file inside an already-folded directory** both take effect immediately. `stow -R` is only required when you introduce a path stow hasn't linked yet (a new package, or a new top-level entry under `$HOME`).

`.stow-local-ignore` entries containing `/` are anchored to the repo root; bare entries match a basename at **any** depth. So `^/README.*` and `^/LICENSE.*` exclude only the *repo-root* files — `nvim/.config/nvim/README.md` and `nvim/.config/nvim/LICENSE` are deliberately still symlinked into `~/.config/nvim`. `.git` and `.gitignore` are excluded everywhere. Add to this file when introducing files that should stay in-repo but never be symlinked.

`zshrc/` and `zed/` are present on disk (and still managed by stow locally) but are **gitignored** while a cross-machine sync strategy is worked out — don't re-add them to tracking without checking with the user first. `~/.zshrc` links straight into `zshrc/.zshrc`, so the shell config still works locally despite being untracked.

When adding a **new** dotfile, place it under a package at the path it should occupy relative to `$HOME` (create the package directory if needed), then re-stow.

## Neovim package (`nvim/`) — non-obvious bits

This is the most substantive config in the repo. It is a **post-NvChad migration**: it dropped the NvChad meta-framework + `lazy.nvim`, but kept the NvChad *look* (chadracula-evondev theme, statusline, tabufline) by loading the `base46` and `ui` plugins directly. See `nvim/.config/nvim/README.md` for full migration notes.

Key constraints when editing nvim config:

- **`init.lua` step order is load-bearing.** `vim.pack.add()` must run before any `require()` of a plugin, and the `base46` highlight cache must exist before plugin configs `dofile()` it. Don't reorder the numbered steps without understanding why.
- **Per-plugin config lives in `lua/setup.lua` → `lua/configs/<plugin>.lua`.** `init.lua` calls `require("setup")` between `vim.pack.add` and `require("nvchad")`; `setup.lua` dispatches into the individual files under `lua/configs/`. Plugin `setup{}` tweaks belong there, not in `plugins.lua`.
- **No lazy-loading.** `vim.pack` (Neovim 0.12+) has no event/cmd/keys deferral and no `build` hooks. Anything that previously ran in a lazy.nvim `build` step is wired up explicitly after `vim.pack.add()` returns.
- **Treesitter is pinned to the `main` branch** in `lua/plugins.lua`. The old `master` branch has injection-query breakage on nvim 0.12. The `main` branch requires the `tree-sitter` CLI on PATH (`brew install tree-sitter-cli`) to compile parsers.
- **`lua/chadrc.lua` carries two unrelated things**: the base46 theme *and* `M.mason.pkgs`, the extra-package list `:MasonInstallAll` (from the NvChad `ui` plugin) installs. LSP servers themselves are not listed here — see `lua/lsp.lua`.
- **After changing the theme** in `lua/chadrc.lua`, run `:BuildHighlights` inside nvim, then restart. The user command is defined at the bottom of `init.lua` and rebuilds the base46 cache.
- **LSP servers** are enabled in `lua/lsp.lua` via `vim.lsp.enable({...})` using nvim 0.11+ APIs (not `lspconfig.setup`). Per-server defaults come from `nvim-lspconfig`'s `lsp/<server>.lua` files on the runtimepath; only override fields go in `vim.lsp.config(...)`.
- **Plugin updates** use `:Pack update` (replaces `:Lazy sync`); `:Pack` lists installed plugins. Mason packages update via `:Mason`.
- **Side-by-side testing.** To try config changes without disturbing the live config, launch with `NVIM_APPNAME=nvim-new nvim` — `vim.pack` clones plugins into `~/.local/share/nvim-new/` and the stowed `~/.config/nvim` symlink stays untouched. See `nvim/.config/nvim/README.md` for the full swap-in procedure.
- **Lock files** (`lazy-lock.json`, `nvim-pack-lock.json`) are gitignored at the repo root — don't commit them.

### Lua formatting

`.stylua.toml` (inside `nvim/.config/nvim/`) governs Lua style: 4-space indent, 120-column width, `AutoPreferDouble` quotes, `call_parentheses = "None"` (so `require "foo"` is preferred over `require("foo")` where stylua would rewrite).

stylua is installed by Mason and is **not on `$PATH`**. Format from the nvim config dir with the absolute path:

```bash
~/.local/share/nvim/mason/bin/stylua .
```

`conform.nvim` also runs it on save inside nvim (`lua/configs/conform.lua`, `format_on_save` with a 500 ms timeout and LSP fallback), so files edited in nvim are already formatted — files edited by tooling outside nvim are not.

## Other packages — quick orientation

- **`starship/`** — single `starship.toml`. Invoked by `eval "$(starship init zsh)"` in `.zshrc`.
- **`tmux/`** — `.tmux.conf` plus `.tmux/scripts/setup-session.sh`. Uses tpm; **tpm must be installed manually** (`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`) — it is not vendored. The `run '~/.tmux/plugins/tpm/tpm'` line must stay the **last** line of `.tmux.conf`; plugin settings added below it are ignored. Theme is catppuccin (`mocha`) via tpm, with dracula/nord/tmux-power left commented out. A `session-created` hook runs `setup-session.sh`, which builds a default dev layout (IDE→`nvim .`, GIT→`lazygit`, Terminal, Logs, Claude→`claude`) for every new session; the same script is bound to `prefix + L` as a manual trigger, and it is idempotent (no-ops when the session already has >1 window). After editing: `prefix + r` reloads the conf, `prefix + I` installs newly added plugins.
- **`kitty/`** — `kitty.conf` picks the colour scheme via a single `include themes/<flavour>.conf` line near the bottom (catppuccin latte/frappe/macchiato/mocha are vendored under `themes/`); font choice is a stack of commented-out `font_family` lines with one active.
- **`gitui/`** — `key_bindings.ron` + `theme.ron`.
