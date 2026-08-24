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
- Keybindings were the gap in the oh-my-zsh migration. `bf79463` deliberately
  reimplemented omz's implicit **history** (`10-history.zsh`) and **completion**
  (`20-completion.zsh`) defaults, but `lib/key-bindings.zsh` was never carried
  over, so prefix history search on the arrow keys silently disappeared —
  restored in `c673aa0`. Two lessons: when a shell feature seems *missing* rather
  than broken, diff the behaviour against `~/.oh-my-zsh/lib/*.zsh` (still on
  disk) rather than `git log -S`, which finds nothing because nothing was ever
  deleted from this repo; and bind both `^[[A` and `^[OA`, since zle switches the
  terminal to application cursor mode via `smkx` and `^[OA` is what actually
  arrives.

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
`call_parentheses = "Always"`.

That last setting used to be `"None"` — the NvChad idiom (`require "cmp"`),
inherited when this config was forked off NvChad. But the code was never written
that way: 19 of 21 files used parentheses, so `stylua --check` failed on all of
them, and because conform.nvim runs stylua on save the tree was quietly
rewriting itself file-by-file as each one was touched.

Both resolutions were measured before choosing: reformatting to `"None"` changes
19 files, switching to `"Always"` changes 0. The codebase was already
self-consistent — only the config disagreed with it — so the config was the thing
that was wrong. `make lint` and CI now enforce stylua as a hard failure rather
than the advisory it was while the mismatch stood.

stylua is installed by Mason and is **not on `$PATH`** (`configs/mason.lua` sets
`PATH = "skip"`). Use the absolute path:

```bash
~/.local/share/nvim/mason/bin/stylua .
```

Note `nvim/lua/options.lua` prepends `~/.local/share/nvim/mason/bin` to
`vim.env.PATH` at startup, so *inside* nvim the Mason tools do resolve. The
`PATH = "skip"` caveat only bites shell invocations like the one above.

### Formatting policy — LSP formatting is banned for data filetypes

`nvim/lua/configs/conform.lua` runs **CLI formatters only** for `yaml`, `json`,
`jsonc`, `toml`, `markdown`, `html` and `xml`. Everything else keeps
`lsp_format = "fallback"`, so rustfmt / gofmt / phpactor still format on save —
a blanket `"never"` would silently regress those.

The reason, verified by reading the vendored source and reproduced end to end:
`yaml-language-server` implements `textDocument/formatting` by calling **bundled
Prettier**. Prettier parses `{{ get_env(name="X") }}` as a *nested YAML flow
mapping* — legal YAML, so nothing throws and the server's own `catch` never
fires — and re-emits it as `{ { get_env(name="X") } }` with `bracketSpacing`
applied at both brace levels, replacing the whole document. One save corrupted
16 expressions in `webtize_ai_backend_rs/config/development.yaml`.

Two traps here, both hit for real:

1. Clearing `yaml.format.enable` is **not sufficient**. `nvim-lspconfig`'s
   `lsp/yamlls.lua` force-sets `documentFormattingProvider = true` in its own
   `on_init`, so conform's `has_lsp_formatter()` check still passes. The
   capability has to be cleared too — see the `vim.lsp.config("yamlls", …)`
   block in `nvim/lua/lsp.lua`.
2. That override **replaces** lspconfig's `on_init`, which in turn shadows the
   one set on `"*"`. So it has to call the shared `on_init` itself, or yamlls
   silently loses the semantic-token strip every other server gets.

On top of both, any buffer in a guarded filetype containing `{{`, `{%` or `<%`
is skipped entirely. The guard is scoped to data and markup filetypes on
purpose — `{{` is ordinary syntax in Rust, Go, JS and Lua. Escape hatches:
`:FormatInfo` (explains a skip, naming the marker and line), `:FormatDisable[!]`,
`:FormatEnable`, `:Format!` (format anyway).

YAML uses `yamlfmt`, not `prettierd`: it normalises indentation and line breaks
but leaves quoting and flow style alone, where Prettier rewrites both.

`postgres_lsp` is enabled but declares `workspace_required = true` with a single
root marker, so it stays dormant until a project carries a
`postgres-language-server.jsonc`. That is intended, not a misconfiguration.

## Other packages

- **tmux** — `~/.config/tmux/`. `run '.../tpm'` must stay the **last line**.
  `TMUX_PLUGIN_MANAGER_PATH` is pinned explicitly because tmux exports it to every
  pane, so a pre-migration session leaks a stale value and tpm then silently finds
  no plugins.

  Catppuccin uses the **v2** API and the ordering is load-bearing:
  set `@catppuccin_*` options → `run catppuccin.tmux` → set `status-left` /
  `status-right` → `run tpm` last. The theme is loaded directly with `run`, not as
  a tpm `@plugin`, because the status line has to be assembled between the theme
  loading and tpm running. Consequently the plugin directory is named
  `catppuccin` (tpm no longer derives it from `basename` of a `@plugin` value) —
  but `tmux-battery` IS a tpm plugin, so *its* directory name must keep matching
  its `@plugin` value.

  Module overrides must be set **before** `run catppuccin.tmux`, because the
  module files use `set -ogq` (assign only if unset). Three traps, each hit for
  real and each documented inline:

  1. Do **not** use `set -gF` for a colour override. `-F` expands immediately,
     before `@thm_*` exists, and silently yields an empty colour — status-right
     renders `#[fg=]` with a blank `bg=`.
  2. A module whose text contains `#(...)` must wrap it in `#{l:...}`, or the
     `-F` expansion of `status-right` executes it **once at parse time** and
     freezes the result. Upstream v2.3.0 does this for `load`, `battery`, `cpu`
     and `ram` but **not** for `uptime` or `gitmux`, so both are re-declared here.
     gitmux froze as *empty*, because there is no pane context during parsing.
  3. `gitmux` is the one module that must be overridden **after** the theme load:
     `status/gitmux.conf` uses plain `set -gq`, not `set -ogq`, so it overwrites
     anything set beforehand.

  Segment toggles use `if-shell`, not tmux's own `%if`. Verified: `%if` conditions
  are evaluated during parsing with no session context, so `#{@my_option}` and
  even `#{ENV:...}` resolve to empty and every branch is skipped —
  `%if "#{==:1,1}"` works while `%if "#{==:#{@knob},on}"` never fires. `if-shell`
  shells out to the real tmux binary and preserves append order (both verified).

  To see the status bar as actually rendered — `display-message -p` does **not**
  execute `#(...)` — attach the server under test inside another tmux and capture
  the pane:

  ```bash
  tmux -L inner -f <conf> new-session -d -s p -x 200 -y 50
  tmux -L outer new-session -d -s cap -x 200 -y 50 "TMUX= tmux -L inner attach -t p"
  sleep 10 && tmux -L outer capture-pane -p -t cap | tail -2
  ```

  `prefix + r` runs `scripts/reload.sh`, not a bare `source-file`. catppuccin
  composes `@catppuccin_status_*` with `set -ogq`, so a plain re-source never
  rebuilds an already-composed module and theme edits appear to do nothing. The
  script unsets `@thm_*` / `@catppuccin_*` / `@_ctp*` first. Verified: after a
  config change, plain `source-file` kept the old colour while unset-then-source
  picked up the new one.
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
