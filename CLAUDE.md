# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## Repository purpose

Personal dotfiles for **macOS and Debian/Ubuntu**, managed with **chezmoi**.
There is no build step. Most files are symlinked into `$HOME`, so editing them
takes effect immediately; the exceptions are listed under *Symlink mode* below.

Migrated from GNU Stow. Anything you find that still describes Stow packages,
`stow -R`, or `.stow-local-ignore` is stale — see `docs/migrating-from-stow.md`.

## Layout

`.chezmoiroot` contains `home`, so **the chezmoi source state is `home/`, not the
repo root**. Everything at the repo root (`README.md`, `CLAUDE.md`, `Makefile`,
`test/`, `.github/`, `nvim/`) is invisible to chezmoi. That is what replaces the
old `.stow-local-ignore` anchoring tricks.

Consequence worth remembering: `.chezmoi.toml.tmpl`, `.chezmoiignore`,
`.chezmoiexternal.toml` and `.chezmoiscripts/` must all live **inside `home/`**.
If `.chezmoi.toml.tmpl` drifts to the repo root, `mode = "symlink"` is never
applied and chezmoi silently *copies* every file instead of symlinking — a
failure mode with no error message. Check with
`test -L ~/.config/kitty/kitty.conf`.

Source-state naming: `dot_` → leading dot, `private_` → 0600, `executable_` →
0755, `create_` → written once and never overwritten, `symlink_` → the file's
contents are the link target, `.tmpl` → rendered as a Go template.

**chezmoi ignores any source file starting with `.` unless it starts with
`.chezmoi`.** So a config file named `.stylua.toml` would have to become
`dot_stylua.toml` to be deployed.

## Symlink mode — the constraint that shapes everything

`mode = "symlink"` is set in `home/.chezmoi.toml.tmpl`. Verified in chezmoi's
source (`internal/chezmoi/sourcestate.go`): it symlinks **individual regular
files**, and only when the entry is not `Template`, `Private`, `Executable` or
`Encrypted`. **Directories are always real directories.** There is no
directory-folding option.

These are therefore **real files, not symlinks**. Editing the deployed copy does
*not* edit the repo; edit the source and `chezmoi apply`:

- `home/dot_gitconfig.tmpl`, `home/dot_config/git/config.work.tmpl`
- `home/dot_config/zsh/create_private_local.zsh.tmpl`
- `home/dot_config/tmux/scripts/executable_setup-session.sh`
- everything in `home/.chezmoiscripts/`

Everything else — kitty, ghostty, zed, starship, all the zsh fragments — is a
live symlink, so editing `~/.config/...` edits this repo directly.

**Never add `exact_` to `dot_config/zed`, `dot_config/kitty` or
`dot_config/ghostty`.** `exact_` deletes anything chezmoi does not manage, which
would wipe `~/.config/zed/{conversations,embeddings,prompts,themes}`.

## `nvim/` lives outside `home/` deliberately

Because of the constraint above, putting the nvim tree in the source state would
give `~/.config/nvim` two dozen individual symlinks instead of one folded
directory link. That would break `git status` inside `~/.config/nvim`, require
`chezmoi apply` for every new file, force `.stylua.toml` → `dot_stylua.toml`, and
stop `.claude/` deploying.

Instead the tree sits at the repo root and `home/dot_config/symlink_nvim.tmpl`
contains `{{ .chezmoi.workingTree }}/nvim`, producing one symlink. Verified:
`.chezmoi.workingTree` resolves to the repo root, not `<repo>/home`.

Practical effects:
- `cd ~/.config/nvim && git status` works. New files appear instantly.
- `nvim-pack-lock.json` lands in `nvim/`, where the root `.gitignore` covers it.
- chezmoi has no visibility into individual nvim files, so `chezmoi diff` never
  reports nvim changes. That is expected, not a bug.

## `.chezmoiignore` semantics

Not gitignore. Patterns match **target** paths with `doublestar.Match`: no
implicit basename matching, no implicit recursion (`*/*.txt` matches one level
only), and `!` negation beats every include. The file is always a template.

Watch out: `*/` inside a Go template comment (`{{/* ... */}}`) closes the comment
early. A path like `.config/*/README.md` written inside a comment breaks the file.

## Editing the shell config

`$ZDOTDIR` is `~/.config/zsh`. `~/.zshenv` is the only zsh file in `$HOME`; it
sets the XDG variables and `ZDOTDIR`, then explicitly sources
`$ZDOTDIR/.zshenv`, because zsh does not re-read that file after `ZDOTDIR`
changes.

`.zshrc` is only a loader over `conf.d/*.zsh`, sourced in ASCII order:

```
00-options 05-path 10-history 20-completion 30-plugins
40-aliases 50-tools 60-prompt 70-darwin 75-linux 99-local
```

Rules that matter:

- **Every fragment is a plain file, never a `.tmpl`.** A template becomes a real
  file and stops being a live symlink. Use runtime `[[ "$OSTYPE" == darwin* ]]`
  guards instead of build-time templating.
- **Never `set -e` / `set -euo pipefail`** in any sourced rc file — an error would
  abort shell startup and lock the user out. That belongs only in
  `.chezmoiscripts/`.
- Guard every tool init with `(( $+commands[x] ))`. Unguarded `eval "$(x init)"`
  is the exact bug this rewrite removed.
- PATH is `typeset -U`, so duplicates collapse automatically. Add paths with the
  `_path_prepend` helper from `05-path.zsh`.
- Layering order is intentional: `70-darwin.zsh` puts Herd ahead of any mise
  shim, so **Herd owns `php` on macOS**. Don't reorder without checking
  `which -a php`.
- Machine-specific values go in `~/.config/zsh/local.zsh` (a `create_` file,
  written once and never overwritten), not into a tracked fragment.

## Neovim specifics

Post-NvChad `vim.pack` config; **requires nvim ≥ 0.12**. `init.lua`'s numbered
step order is load-bearing: `vim.pack.add()` must precede any `require()` of a
plugin, and the base46 highlight cache must exist before plugin configs `dofile()`
it. Per-plugin config is `lua/setup.lua` → `lua/configs/<plugin>.lua`.

Commands that actually exist — the previous version of this file was wrong about
two of them:

| Task | Correct invocation |
|---|---|
| Update plugins | `:lua vim.pack.update()`. **`:Pack` does not exist** — `vim.pack` is a Lua API, not an ex command. Headless needs `{ force = true }` to skip the confirmation buffer. |
| Install Mason packages | `:MasonInstallAll` works interactively but is **not available headless** (the NvChad `ui` plugin registers it, and `install_all()` is async and calls `:Mason`). Headless: take the list from `require("nvchad.mason").get_pkgs()` and pass packages to `:MasonInstall` one at a time. |
| Rebuild highlight cache | `:BuildHighlights` (defined at the bottom of `init.lua`), then restart |
| Update Mason packages | `:Mason` |

`nvim-treesitter` is pinned to its `main` branch, which needs the `tree-sitter`
CLI on PATH to compile parsers. `lua/configs/treesitter.lua` exports
`{ parsers = ... }` so the bootstrap script compiles exactly that list without
duplicating it — keep that return value if you edit the file.

`lua/chadrc.lua` carries two unrelated things: the base46 theme and
`M.mason.pkgs`. LSP servers are enabled in `lua/lsp.lua` via `vim.lsp.enable()`
(nvim 0.11+ API), not `lspconfig.setup`.

Side-by-side testing: `NVIM_APPNAME=nvim-test nvim`.

### Lua formatting

`nvim/.stylua.toml`: 4-space indent, 120 columns, `AutoPreferDouble` quotes,
`call_parentheses = "None"`.

**Known inconsistency:** 19 of 21 Lua files are written with `require("x")` while
the config declares `call_parentheses = "None"`. conform.nvim reformats each file
on save inside nvim, so the tree drifts file-by-file. `make lint` reports this as
an advisory, not a failure. Resolve it deliberately — `make fmt-lua` to reformat
everything, or change `.stylua.toml` to match the existing style — but do not
sneak a 19-file reformat into an unrelated change.

stylua is installed by Mason and is **not on `$PATH`** (`configs/mason.lua` sets
`PATH = "skip"`). Use the absolute path:

```bash
~/.local/share/nvim/mason/bin/stylua .
```

## Other packages

- **tmux** — `~/.config/tmux/`. `run '.../tpm'` must stay the **last line**.
  `TMUX_PLUGIN_MANAGER_PATH` is pinned explicitly because tmux exports it to every
  pane, so a pre-migration session leaks a stale value and tpm then silently finds
  no plugins. Catppuccin's directory must be named `tmux`, not `catppuccin` — tpm
  derives the path from `basename` of the `@plugin` value. The `@catppuccin_*`
  options are stale v0.3 names; rewriting them for v2 is an open follow-up.
- **ghostty** — primary terminal. Shared `config` plus `config.darwin` /
  `config.linux`, combined via Ghostty's own `config-file = ?<file>` includes and
  gated by `.chezmoiignore`. Theme names are exact filenames with spaces:
  `Catppuccin Mocha`, not `catppuccin-mocha`. `adjust-*` values are **deltas**,
  not targets. Validate with `ghostty +validate-config`.
- **kitty** — fallback only. Keep it working.
- **starship**, **zed**, **git**, **mise**, **homebrew/Brewfile**,
  **packages/debian.txt** — see the README table.

The Brewfile is **hand-maintained**. Never run `brew bundle dump` over it: it is
platform-unaware and strips the `OS.mac?` / `OS.linux?` guards
(homebrew/brew#22417). Also note `brew bundle --no-lock` was removed in Homebrew
6.x and now makes brew print its usage and exit non-zero.

## Provisioning scripts

`home/.chezmoiscripts/`, ordered by numeric prefix. `before_` runs before any
file, symlink or external; `after_` runs after everything. Anything that must
exist before configs land goes `before_`; anything that consumes a config file
goes `after_`.

`run_onchange_` scripts inline the manifest's hash in a comment
(`{{ include "..." | sha256sum }}`) so they re-run exactly when the package list
changes. Read manifests via `joinPath .chezmoi.sourceDir ...`, not the deployed
path — on a first run in a `before_` script the symlink does not exist yet.

`chsh` is deliberately the last script, so a failure upstream can never leave the
user without a working login shell.

Reset `run_once_` state with `chezmoi state delete-bucket --bucket=scriptState`.

## Verification

```bash
make lint      # shellcheck + shfmt on rendered templates, zsh -n, stylua advisory
make doctor    # this machine: drift, detached symlinks, missing tools
make test      # full bootstrap in a clean ubuntu:24.04 container, run TWICE
chezmoi diff   # before any apply
```

`make test` running the bootstrap twice is the important one: a bootstrap that
works once but is not idempotent corrupts a machine on the next `make update`.

Rehearse risky changes without touching `$HOME`:

```bash
chezmoi -D /tmp/cz-dest apply --force --exclude=scripts,externals
```

## Working conventions

- Commit per logical change, and leave the machine working after each one.
- Verify claims against the running system rather than the docs. Several
  documented commands in this stack do not exist (`:Pack`, headless
  `:MasonInstallAll`, `brew bundle --no-lock`), and tmux expands `$HOME` but not
  a bare `~` in `set-environment`.
- Don't bring credential files under management (`~/.config/gh/hosts.yml` holds
  auth tokens). Identity belongs in `~/.config/chezmoi/chezmoi.toml`; secrets in
  `~/.config/zsh/local.zsh`.
