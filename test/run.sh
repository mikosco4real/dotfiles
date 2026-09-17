#!/usr/bin/env bash
# Run the real bootstrap in a clean container, twice, and assert that the second
# run changes nothing.
#
# The second run is the whole point. A bootstrap that works once but is not
# idempotent will quietly corrupt a machine on the next `make update`.
#
#   ./test/run.sh                  build + test on Ubuntu 24.04 (default)
#   ./test/run.sh --distro arch    build + test on Arch
#   ./test/run.sh --shell          build, then drop into an interactive shell
#   ./test/run.sh --no-build       reuse the existing image
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISTRO="ubuntu"
# Expanded as ${PLATFORM_ARGS[@]+"${...[@]}"} everywhere below: macOS still
# ships bash 3.2, which under `set -u` treats "${arr[@]}" on an empty array as
# an unbound variable rather than as nothing.
PLATFORM_ARGS=()
BUILD=1
SHELL_MODE=0

while (($#)); do
  case "$1" in
    --shell) SHELL_MODE=1 ;;
    --no-build) BUILD=0 ;;
    --distro)
      shift
      DISTRO="${1:-}"
      ;;
    --distro=*) DISTRO="${1#*=}" ;;
    -h | --help)
      sed -n '2,11p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "unknown flag: $1" >&2
      exit 1
      ;;
  esac
  shift
done

# One Dockerfile per distro rather than one ARG-parameterised file: the pacman
# and apt preambles differ enough that a single file would be mostly branching.
case "$DISTRO" in
  ubuntu)
    IMAGE="dotfiles-test:ubuntu24"
    DOCKERFILE="$REPO_ROOT/test/Dockerfile.ubuntu"
    DISTRO_LABEL="Ubuntu 24.04"
    ;;
  arch)
    IMAGE="dotfiles-test:arch"
    DOCKERFILE="$REPO_ROOT/test/Dockerfile.arch"
    DISTRO_LABEL="Arch"
    # Arch publishes no arm64 image, so on Apple Silicon this has to run
    # emulated. Ask for the platform explicitly rather than letting docker fail
    # with "no matching manifest for linux/arm64".
    if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
      PLATFORM_ARGS=(--platform linux/amd64)
    fi
    ;;
  *)
    echo "unknown distro: $DISTRO (expected 'ubuntu' or 'arch')" >&2
    exit 1
    ;;
esac

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31mFAIL\033[0m %s\n' "$*" >&2
  exit 1
}

command -v docker > /dev/null 2>&1 || die "docker not found"
docker info > /dev/null 2>&1 || die "docker daemon is not running"

if ((BUILD)); then
  log "Building $IMAGE"
  docker build -q ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} -t "$IMAGE" -f "$DOCKERFILE" "$REPO_ROOT" > /dev/null
fi

if ((SHELL_MODE)); then
  log "Interactive shell — the repo is at /dotfiles (read-only)"
  exec docker run --rm -it ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" /bin/bash
fi

# The container script. Copies the repo out of the read-only mount so chezmoi can
# treat it as a normal source directory, then inits and applies twice.
read -r -d '' CONTAINER_SCRIPT << 'EOF' || true
set -euo pipefail
log() { printf '\033[1;36m  [container]\033[0m %s\n' "$*"; }

cp -r /dotfiles "$HOME/.local/share/chezmoi-src" 2>/dev/null || {
  mkdir -p "$HOME/.local/share"
  cp -r /dotfiles "$HOME/.local/share/chezmoi-src"
}
rm -rf "$HOME/.local/share/chezmoi-src/.git"
mv "$HOME/.local/share/chezmoi-src" "$HOME/.local/share/chezmoi"

log "chezmoi init (non-interactive, prompt defaults)"
chezmoi init --promptDefaults

log "=== FIRST APPLY ==="
chezmoi apply --verbose 2>&1 | tail -25

log "=== ASSERTIONS ==="
fail=0
check() {
  if eval "$2"; then
    printf '    ok    %s\n' "$1"
  else
    printf '    FAIL  %s\n' "$1"
    fail=1
  fi
}

# The single most valuable assertion: the shell must actually start. This is the
# class of bug the old unguarded `eval "$(pyenv init --path)"` represented.
check "interactive zsh starts"        'zsh -i -c "exit" 2>/dev/null'
check "login zsh starts"              'zsh -l -i -c "exit" 2>/dev/null'
check "ZDOTDIR is set correctly"      '[ "$(zsh -l -i -c "printf %s \$ZDOTDIR" 2>/dev/null)" = "$HOME/.config/zsh" ]'
check "no oh-my-zsh leaked in"        '[ -z "$(zsh -l -i -c "printf %s \${ZSH:-}" 2>/dev/null)" ]'
check "PATH has no duplicates"        '[ "$(zsh -l -i -c "print -l \$path" 2>/dev/null | sort | uniq -d | wc -l)" -eq 0 ]'
check "~/.zshenv deployed"            '[ -L "$HOME/.zshenv" ] || [ -f "$HOME/.zshenv" ]'
check "conf.d fragments deployed"     '[ "$(ls "$HOME/.config/zsh/conf.d/" | wc -l)" -ge 10 ]'
check "local.zsh seeded 0600"         '[ "$(stat -c %a "$HOME/.config/zsh/local.zsh")" = "600" ]'
check "nvim config is ONE symlink"    '[ -L "$HOME/.config/nvim" ]'
check "nvim .stylua.toml intact"      '[ -f "$HOME/.config/nvim/.stylua.toml" ]'
check "tmux.conf at XDG path"         '[ -e "$HOME/.config/tmux/tmux.conf" ]'
check "session script executable"     '[ -x "$HOME/.config/tmux/scripts/setup-session.sh" ]'
check "weather script executable"     '[ -x "$HOME/.config/tmux/scripts/weather.sh" ]'
check "reload script executable"      '[ -x "$HOME/.config/tmux/scripts/reload.sh" ]'
check "tpm vendored"                  '[ -x "$HOME/.config/tmux/plugins/tpm/tpm" ]'
check "catppuccin vendored"           '[ -f "$HOME/.config/tmux/plugins/catppuccin/catppuccin.tmux" ]'
check "tmux-battery vendored"         '[ -x "$HOME/.config/tmux/plugins/tmux-battery/scripts/battery_percentage.sh" ]'
check "tmux-cpu vendored"             '[ -x "$HOME/.config/tmux/plugins/tmux-cpu/scripts/cpu_percentage.sh" ]'
check "gitmux config deployed"        '[ -e "$HOME/.gitmux.conf" ]'
check "zsh plugins vendored"          '[ -f "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]'
check "gitconfig rendered"            'grep -q "\[user\]" "$HOME/.gitconfig"'
check "git identity resolves"         '[ -n "$(git config --global user.email)" ]'
check "ghostty linux override only"   '[ -f "$HOME/.config/ghostty/config.linux" ] && [ ! -e "$HOME/.config/ghostty/config.darwin" ]'
check "no macOS-only files leaked"    '[ ! -d "$HOME/Library" ]'
check "no broken symlinks"            '[ -z "$(find "$HOME" -maxdepth 4 -xtype l 2>/dev/null)" ]'

log "=== SECOND APPLY (must be a no-op) ==="
second="$(chezmoi apply --verbose 2>&1 || true)"
printf '%s\n' "$second" | tail -15
if printf '%s' "$second" | grep -qE '^(\+\+\+ b/|--- a/)'; then
  printf '    FAIL  second apply was NOT idempotent — it changed files:\n'
  printf '%s\n' "$second" | grep -E '^\+\+\+ b/' | sed 's/^/      /'
  fail=1
else
  printf '    ok    second apply changed nothing\n'
fi

status="$(chezmoi status || true)"
if [ -n "$status" ]; then
  printf '    FAIL  chezmoi status is dirty after apply:\n%s\n' "$status"
  fail=1
else
  printf '    ok    chezmoi status clean\n'
fi

exit "$fail"
EOF

log "Running bootstrap in $IMAGE (this pulls packages; first run is slow)"
if docker run --rm ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" /bin/bash -c "$CONTAINER_SCRIPT"; then
  log "PASS — bootstrap works on a clean $DISTRO_LABEL and is idempotent"
else
  die "bootstrap test failed (see output above)"
fi
