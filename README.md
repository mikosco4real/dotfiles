# dotfiles

Personal development environment for macOS and Debian/Ubuntu Linux, managed with
[chezmoi](https://www.chezmoi.io/). One command on a bare machine produces a
working, identical setup: zsh, Neovim, tmux, Ghostty, starship, git.

Nothing in this repo is machine-specific. Identity and secrets are supplied at
`chezmoi init` time and live outside version control.

---

## What's in here

| Tool | Deployed to | Notes |
|---|---|---|
| **zsh** | `~/.zshenv`, `~/.config/zsh/` | `$ZDOTDIR` under XDG. Numbered `conf.d/*.zsh` fragments, no framework. ~100 ms startup. |
| **Neovim** | `~/.config/nvim` | Post-NvChad, standalone `vim.pack`. **Requires nvim ≥ 0.12.** Deployed as one folded symlink. |
| **tmux** | `~/.config/tmux/` | Truecolor + undercurl, OSC 52 clipboard, auto session layout, catppuccin via tpm. |
| **Ghostty** | `~/.config/ghostty/` | Primary terminal. Shared config plus per-OS overrides. |
| **kitty** | `~/.config/kitty/` | Kept as a working fallback. |
| **starship** | `~/.config/starship.toml` | Prompt. Catppuccin Mocha palette. |
| **Zed** | `~/.config/zed/` | Secondary editor, vim mode on. |
| **git** | `~/.gitconfig`, `~/.config/git/` | Templated identity; work vs personal chosen by **remote URL**. |
| **mise** | `~/.config/mise/config.toml` | node / python / bun versions. Replaces nvm + pyenv. |
| **Homebrew** | `~/.config/homebrew/Brewfile` | Package manifest, with `OS.mac?` / `OS.linux?` guards. |
| **apt** | `~/.config/packages/debian.txt` | Linux system packages. |

Colour scheme is **Catppuccin Mocha** throughout. Fonts are **VictorMono Nerd
Font** (terminal) and **JetBrainsMono Nerd Font** (Zed) — both are hard
requirements, not decoration: starship, the tmux theme and the terminal configs
all use Nerd Font glyphs.

---

## Quick start

On a machine with nothing installed, not even chezmoi:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply mikosco4real
```

That is the whole thing. chezmoi installs itself, finds
`github.com/mikosco4real/dotfiles`, clones it, prompts for the values below, and
applies.

You are prompted for six values, each with a default, so holding Enter is fine:

| Prompt | Used for |
|---|---|
| Full name | `user.name` in git |
| Personal git email | default git identity |
| Work git email | applied only to work-org repos; blank to skip |
| Work git org | matched against remote URLs |
| Machine class | `personal` or `work` |
| Desktop machine? | answering no skips all GUI apps and fonts |

Answers are written to `~/.config/chezmoi/chezmoi.toml`, **not** to this repo.

To look before you leap:

```sh
git clone https://github.com/mikosco4real/dotfiles.git ~/.local/share/chezmoi
chezmoi init                     # writes the config, changes nothing else
chezmoi diff                     # review every change first
chezmoi apply --verbose
```

---

## Supported platforms

| Platform | Status |
|---|---|
| macOS 14+ on Apple Silicon | primary, developed here |
| macOS on Intel | supported — the brew prefix is probed, not hardcoded |
| Ubuntu 24.04 / 22.04, Debian 12+ | supported, CI-tested in containers on every push |
| Arch, Fedora, others | **not supported.** The apt path is Debian-only; the shell config itself is portable. |
| Windows | no |

---

## What the installer actually does

In order, and safe to re-run:

1. **`run_once_before_00`** — installs Homebrew (macOS), or `build-essential`,
   `curl`, `git`, `zsh` plus Homebrew-on-Linux (Debian). First, because chezmoi's
   git-repo externals need `git`.
2. **`run_onchange_before_10`** — `brew bundle` from the Brewfile.
3. **`run_onchange_before_11`** — apt packages, and Ghostty from the
   `mkasberg/ghostty-ubuntu` PPA (Linux only).
4. **Files and symlinks** are written.
5. **Externals** are fetched: tpm, catppuccin, three zsh plugins, and Nerd Fonts
   on Linux.
6. **`run_once_after_20/21`** — mise, then `mise install` for the runtimes.
7. **`run_onchange_after_30`** — reloads a live tmux server.
8. **`run_once_after_40`** — Neovim: sync plugins, build the base46 highlight
   cache, install Mason packages, compile treesitter parsers. The slow step, and
   the reason nvim works on first open with no manual commands.
9. **`run_once_after_60`** — `fc-cache` once the fonts land (Linux).
10. **`run_once_after_90`** — `chsh` to zsh. **Deliberately last**: if anything
    above failed, your login shell is untouched.

Homebrew on Linux is a top-up only, for CLI tools whose apt versions are too old
or renamed — Ubuntu 24.04 ships Neovim 0.9.x against this config's 0.12
requirement, and Debian installs `bat` as `batcat` and `fd` as `fdfind`.

---

## Repository structure

```
.
├── home/                    ← chezmoi source state (.chezmoiroot points here)
│   ├── .chezmoi.toml.tmpl       init prompts; sets mode = "symlink"
│   ├── .chezmoiignore           OS / GUI gating (a template)
│   ├── .chezmoiexternal.toml    vendored plugins + Linux fonts
│   ├── .chezmoiscripts/         ordered provisioning
│   ├── dot_zshenv               → ~/.zshenv
│   ├── dot_gitconfig.tmpl       → ~/.gitconfig
│   └── dot_config/
│       ├── symlink_nvim.tmpl    → the folded ~/.config/nvim symlink
│       ├── zsh/{,conf.d/}       shell config
│       ├── tmux/  ghostty/  kitty/  zed/  git/  mise/
│       ├── starship.toml
│       ├── homebrew/Brewfile
│       └── packages/debian.txt
├── nvim/                    ← OUTSIDE home/, on purpose. See below.
├── test/                    Docker harness
├── .github/workflows/ci.yml
├── Makefile
└── docs/migrating-from-stow.md
```

**Why `nvim/` sits outside `home/`.** chezmoi's `mode = "symlink"` symlinks
individual *files* and never folds a directory. Left alone, `~/.config/nvim`
would become a real directory holding two dozen separate symlinks — which breaks
`git status` inside the config dir, needs a `chezmoi apply` for every new file,
and forces `.stylua.toml` to be renamed `dot_stylua.toml` (chezmoi ignores
dot-prefixed source files). Keeping the tree outside the source state and
deploying one `symlink_nvim.tmpl` entry reproduces the previous GNU Stow
behaviour exactly.

---

## Day-2 operations

```sh
make                # list every target
make diff           # what would change
make apply          # apply
make update         # git pull → apply → refresh externals → brew bundle → mise install
make status         # which managed files have drifted
make doctor         # is this machine's install still intact?
make lint           # shellcheck + shfmt + zsh -n + stylua
make test           # full bootstrap in a clean container, twice
```

**Editing config.** Almost everything is a live symlink into this repo, so open
the deployed path and edit it directly — `nvim ~/.config/zsh/conf.d/40-aliases.zsh`
edits the repo. No `chezmoi add`, no `chezmoi edit`.

A few are **real files, not symlinks**, because symlink mode exempts templates
and `private_` / `create_` / `executable_` entries. Edit the source, then
`chezmoi apply`:

- `~/.gitconfig` and `~/.config/git/config.work` (templates)
- `~/.config/tmux/scripts/setup-session.sh` (executable)
- `~/.config/zsh/local.zsh` (seeded once, then yours forever)

`make doctor` reports any symlink that has become a real file — Zed in particular
can rewrite `settings.json` from its UI and silently detach it.

**Adding a new dotfile:** create it in the right place under `home/dot_config/`,
then `chezmoi apply`. Prefix a leading dot with `dot_`, and remember that a
`.tmpl` suffix makes it a real file instead of a symlink.

---

## Machine-specific values and secrets

Three layers, none of which put anything private in this repo:

1. **`chezmoi init` prompts** → `~/.config/chezmoi/chezmoi.toml`. Name, emails,
   machine class, GUI flag. Used by templates as `{{ .email }}` and friends.
2. **`~/.config/zsh/local.zsh`** — created once by chezmoi at mode 0600 and never
   overwritten. API keys, one-off PATH additions, work VPN variables. It lives
   outside the repo, so it cannot be committed by accident.
3. **`~/.config/ghostty/config.local`** and **`~/.config/tmux/local.conf`** —
   optional, untracked, loaded only if present.

`gitleaks` runs as a pre-commit hook as a backstop.

**Git identity** switches on the **remote URL**, not the directory:

```
[includeIf "hasconfig:remote.*.url:git@github.com:webtize/**"]
	path = ~/.config/git/config.work
```

A `gitdir:` rule would be wrong here — work repos live in both `~/Herd` and
`~/workspace`, and `~/workspace` also holds personal ones. Needs git ≥ 2.36.

---

## Per-tool notes

### Neovim

Post-NvChad: dropped the meta-framework and `lazy.nvim`, kept the look by loading
`base46` and `ui` directly. **Needs nvim ≥ 0.12** for `vim.pack`, and the
`tree-sitter` CLI on PATH because nvim-treesitter is pinned to its `main` branch.

- Update plugins: `:lua vim.pack.update()` — **not** `:Pack`, which does not exist
- After changing the theme in `lua/chadrc.lua`: `:BuildHighlights`, then restart
- LSP servers: `lua/lsp.lua`, via `vim.lsp.enable()` (nvim 0.11+ API)
- Format Lua outside nvim: `~/.local/share/nvim/mason/bin/stylua .` — Mason sets
  `PATH = "skip"`, so stylua is not on `$PATH`
- Try changes safely: `NVIM_APPNAME=nvim-test nvim`

### tmux

Prefix stays `C-b`. `prefix + L` re-applies the IDE/GIT/Terminal/Logs/Claude
window layout, which is also automatic for every new session and is idempotent.
`run '.../tpm'` **must stay the last line** — anything after it is ignored.

Status line (Catppuccin **v2** API): window tabs are rounded pills showing the
window *name*; the right side carries weather, battery and date/time/timezone.

| Segment | Source |
|---|---|
| Weather — location, condition, temperature | `scripts/weather.sh`, a local 15-minute-cached wttr.in call. Set the place with `set -g @weather_location "..."`. |
| Battery icon + percentage | `tmux-plugins/tmux-battery`, vendored |
| Date, time, timezone | catppuccin `date_time` module |

`prefix + r` runs `scripts/reload.sh` rather than a bare `source-file`.
catppuccin composes `@catppuccin_status_*` with `set -ogq` (assign only if
unset), so a plain re-source never rebuilds an already-composed module and theme
edits silently appear to do nothing. The script clears the theme's options first,
without dropping any session.

To add more segments, set the override *before* `run catppuccin.tmux` and append
with `set -agF status-right "#{E:@catppuccin_status_<module>}"`. Available
modules: `application session user host date_time directory battery cpu ram load
uptime weather clima gitmux kube pomodoro_plus`. Some need their own plugin —
see the
[module reference](https://github.com/catppuccin/tmux/blob/main/docs/reference/status-line.md).

### Ghostty

`config` is shared; `config.darwin` and `config.linux` are pulled in with
`config-file = ?config.<os>`, and chezmoi deploys only the matching one. Validate
with `ghostty +validate-config`; reload with `Cmd/Ctrl+Shift+,`.

On macOS, Ghostty also reads
`~/Library/Application Support/com.mitchellh.ghostty/config` *after* the XDG file,
so that path was renamed to `.bak`. Restoring it would override this config.

### zsh

Fragments load in ASCII order from `~/.config/zsh/conf.d/`. `70-darwin.zsh` and
`75-linux.zsh` self-guard on `$OSTYPE`. Never put `set -e` in any of them — an
error would abort shell startup and lock you out of your terminal.

---

## Uninstall

```sh
chezmoi purge          # removes chezmoi's own state; leaves $HOME as-is
```

chezmoi produces real files and symlinks, so walking away is a no-op — unlike
abandoning GNU Stow, which leaves dangling symlinks to resolve by hand. To also
remove the deployed files, `chezmoi unmanage` them first, or delete the paths
listed by `chezmoi managed`.

---

## Migrating from the old GNU Stow layout

See [`docs/migrating-from-stow.md`](docs/migrating-from-stow.md) for what moved
where, and the rollback recipe.

---

## Credits

Structure and conventions borrowed from
[twpayne/dotfiles](https://github.com/twpayne/dotfiles),
[Lissy93/dotfiles](https://github.com/Lissy93/dotfiles) and
[webpro/dotfiles](https://github.com/webpro/dotfiles).
Themes by [Catppuccin](https://github.com/catppuccin).
