# beads hub helpers. The hub itself is ~/hub; `bdh` (~/.local/bin/bdh) runs bd
# against it from any directory. See CLAUDE.md, "beads hub".
#
# Deliberately NOT here: `export BEADS_DIR=...`. It would override every repo's
# own .beads/ for the whole shell. bdh scopes it to one process instead.
#
# And deliberately not called `done`: that is a zsh reserved word, and an alias
# or function by that name breaks every for/while loop typed at the prompt.

(( $+commands[bd] )) || return 0

# owner/name of the current repo's origin, for the repo:<owner>/<name> label.
# Handles git@host:owner/name.git and https://host/owner/name(.git).
_hub_repo_slug() {
  local url
  url=$(git remote get-url origin 2> /dev/null) || return 1
  url=${${url%.git}//:/\/}
  print -r -- "${${url:h}:t}/${url:t}"
}

# did "Reviewed the rollout plan with Priya"
# Logs work you did yourself as an already-closed bead, so the daily report
# (`hub report`) sees it. Inside a git repo it is tagged repo:<owner>/<name>.
did() {
  if (( ! $# )); then
    print -u2 'usage: did "what you did"   — logs a closed bead in the hub'
    return 1
  fi
  local labels=manual slug id
  slug=$(_hub_repo_slug) && labels+=",repo:$slug"
  id=$(bdh create "$*" -t task -l "$labels" --silent) || return
  bdh close "$id" -r done > /dev/null || return
  print -r -- "logged $id${slug:+ ($slug)}"
}

# todo "Chase IT about the Teams webhook"   — add a to-do only you can do
# todo                                       — list your open to-dos
# Labelled `human`, which the dispatcher never picks up.
todo() {
  if (( ! $# )); then
    bdh list -l human
    return
  fi
  local labels=human slug id
  slug=$(_hub_repo_slug) && labels+=",repo:$slug"
  id=$(bdh create "$*" -t task -l "$labels" -a "$(git config --global user.name)" --silent) || return
  print -r -- "added $id${slug:+ ($slug)}"
}

# Homebrew/AUR install bd's own completion; give bdh the same one.
(( $+functions[compdef] )) && compdef bdh=bd
