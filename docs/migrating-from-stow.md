# Migrating from GNU Stow to chezmoi

Record of the migration, kept so the rollback recipe stays available and so the
reasoning behind the layout is not lost.

## Why

Stow has no mechanism for per-machine values. The old `.gitignore` admitted it:

```
# Temporarily untracked while a cross-machine sync strategy is worked out.
zshrc/
zed/
```

The shell config — the most important dotfile in the repo — was untracked because
it could not be shared. It carried 11 hardcoded `/Users/mokolo/...` paths (8 of
them Laravel Herd), two `/opt/homebrew/opt/php@8.2` paths, a byte-identical
duplicate `antigravity` PATH export, and two unguarded `eval` calls that
hard-error on any machine without pyenv or starship. There was no `uname` check
or `$OSTYPE` branch anywhere in the repo.

Stow also cannot express per-machine values for non-shell files —
`starship.toml`, `kitty.conf`, `gitconfig` — because shell conditionals do not
apply to them.

## What moved where

| Before (Stow package) | After |
|---|---|
| `nvim/.config/nvim/` | `nvim/` — repo root, **outside** `home/` |
| `kitty/.config/kitty/` | `home/dot_config/kitty/` |
| `starship/.config/starship.toml` | `home/dot_config/starship.toml` |
| `tmux/.tmux.conf` | `home/dot_config/tmux/tmux.conf` |
| `tmux/.tmux/scripts/setup-session.sh` | `home/dot_config/tmux/scripts/executable_setup-session.sh` |
| `zed/.config/zed/` (was gitignored) | `home/dot_config/zed/` — now tracked |
| `zshrc/.zshrc` (was gitignored) | split into `home/dot_zshenv` + `home/dot_config/zsh/**` |
| `gitui/` | **dropped** — config was stowed but the binary was never installed |
| `.stow-local-ignore` | **deleted** — `.chezmoiroot` replaces it |

All tracked moves were done as a single commit of pure `git mv`s, so
`git log --follow` and `git blame` still work across the rename. The two
gitignored packages had already lost their history at commit `e400494`.

New, previously unmanaged: `~/.gitconfig`, `~/.zshenv`, `~/.zprofile`, the
Brewfile, the apt list, the mise config, and the Ghostty config.

## Deployed-path changes

| Before | After |
|---|---|
| `~/.zshrc` | `~/.config/zsh/.zshrc` (`$ZDOTDIR`); `~/.zshenv` is the only zsh file left in `$HOME` |
| `~/.tmux.conf` | `~/.config/tmux/tmux.conf` |
| `~/.tmux/scripts/` | `~/.config/tmux/scripts/` |
| `~/.tmux/plugins/` | `~/.config/tmux/plugins/` |
| `~/.config/gitui` | removed |

`~/.dotfiles` is now a symlink to `~/.local/share/chezmoi`, chezmoi's default
source directory. Keeping the repo at the default path is what makes the
one-command bootstrap work with no flags on a new machine; the symlink preserves
muscle memory.

## Files kept for rollback

Not deleted, in case something surfaces later:

```
~/dotfiles-pre-chezmoi.bundle              full git bundle of the pre-migration repo
~/premigration-<date>.tgz                  $HOME dotfiles, symlinks dereferenced
~/.gitconfig.pre-chezmoi
~/.zprofile.pre-chezmoi
~/.tmux.pre-chezmoi/                       old tmux tree incl. plugins
~/.zshrc.pre-oh-my-zsh                     predates even the Stow setup
~/.oh-my-zsh/                              22 MB, now unused
~/Library/Application Support/com.mitchellh.ghostty/config.bak
```

Also still on disk and now unused: `~/.nvm`, `~/.pyenv` (both replaced by mise),
and `~/.local/share/nvim.nvchad-backup-2026-05-22` plus its `state` counterpart
(~1.15 GB from the May 2026 NvChad migration). Safe to delete once you are
confident; deliberately left alone here.

## Rollback

The pre-migration state is tagged:

```sh
git -C ~/.local/share/chezmoi tag -l          # pre-chezmoi
```

Full revert:

```sh
cd ~/.local/share/chezmoi
git reset --hard pre-chezmoi
# restore the repo to its old location
rm ~/.dotfiles && mv ~/.local/share/chezmoi ~/.dotfiles
cd ~/.dotfiles && stow -R nvim kitty starship tmux zshrc zed
tar xzf ~/premigration-<date>.tgz -C ~        # restores ~/.zshrc, ~/.zprofile, etc.
```

Nuclear option, if the repo itself is lost:

```sh
git clone ~/dotfiles-pre-chezmoi.bundle ~/.dotfiles-restored
```

Note `chezmoi purge` removes chezmoi's own state and configuration but leaves
`$HOME` untouched — unlike abandoning Stow, which leaves dangling symlinks behind.

## Gotchas discovered during the migration

Recorded because each one cost real debugging time:

1. **`mode = "symlink"` does not fold directories.** It symlinks individual
   regular files. `~/.config/nvim` would have become 24 separate symlinks. Fixed
   by keeping `nvim/` outside the source state and using one `symlink_` entry.
2. **`.chezmoi.toml.tmpl` must live inside `home/`** when `.chezmoiroot` is set.
   Otherwise `mode = "symlink"` is never read and chezmoi silently *copies*
   everything, with no error.
3. **`*/` inside a Go template comment closes the comment.** A `.config/*/README.md`
   example inside a `{{/* ... */}}` block broke `.chezmoiignore` on the first run.
4. **`brew bundle --no-lock` was removed in Homebrew 6.x.** Passing it makes brew
   print usage and exit non-zero, which an error handler happily swallowed — so
   the first provisioning run installed nothing and looked like it had worked.
5. **`:Pack update` does not exist.** The old CLAUDE.md documented it as the
   `:Lazy sync` replacement, but `vim.pack` is a Lua API. Use
   `vim.pack.update(nil, { force = true })` — `force` skips the confirmation
   buffer, which hangs headless.
6. **`:MasonInstallAll` is unavailable headless.** It is registered by the NvChad
   `ui` plugin, and `install_all()` is async and calls `:Mason`, which needs a UI.
7. **tmux exports `TMUX_PLUGIN_MANAGER_PATH` into every pane.** A session started
   before the migration leaked the old `~/.tmux/plugins/` value into any server
   launched from inside it, so tpm found no plugins — silently, because it pipes
   plugin output to `/dev/null`. Now pinned explicitly in `tmux.conf`.
8. **tmux expands `"$HOME"` but not a bare `~` in `set-environment`.** The
   quoting on that line is load-bearing.
9. **Catppuccin's tmux directory must be named `tmux`.** tpm derives the plugin
   path from `basename` of the `@plugin` value, not by globbing the plugins dir.
10. **Ghostty theme names are exact filenames with spaces.** `catppuccin-mocha`
    does not resolve; a lowercase variant would work on APFS and break on ext4.
11. **Ghostty's `adjust-*` values are deltas, not targets.** Copying kitty's
    `adjust_line_height 120%` verbatim gives a 2.2× cell; the correct value is
    `20%`.
