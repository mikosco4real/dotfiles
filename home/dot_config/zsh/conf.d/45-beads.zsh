# beads hub helpers. The hub itself is ~/hub; `bdh` (~/.local/bin/bdh) runs bd
# against it from any directory. See CLAUDE.md, "beads hub".
#
# Deliberately NOT here: `export BEADS_DIR=...`. It would override every repo's
# own .beads/ for the whole shell. bdh scopes it to one process instead.
#
# And deliberately not called `done`: that is a zsh reserved word, and an alias
# or function by that name breaks every for/while loop typed at the prompt.

(( $+commands[bd] )) || return 0

# owner/name, lower-cased, from any of: owner/name, https://host/owner/name(.git),
# git@host:owner/name(.git). Fails on anything without both parts.
_hub_norm_slug() {
  local s=${${1%/}%.git}
  s=${s//:/\/}
  local name=${s:t} owner=${${s:h}:t}
  [[ -n "$name" && -n "$owner" && "$owner" != "." && "$s" == */* ]] || return 1
  print -r -- "${(L)owner}/${(L)name}"
}

# owner/name of the current repo's origin, for the repo:<owner>/<name> label.
_hub_repo_slug() {
  local url
  url=$(git remote get-url origin 2> /dev/null) || return 1
  _hub_norm_slug "$url"
}

# Shared by did and todo: consume a leading `-r|--repo <repo>` (or --repo=<repo>)
# and `--`. Sets the CALLER's _hub_slug and _hub_n (args consumed); zsh's
# dynamic scoping makes the caller's locals visible here.
_hub_repo_opt() {
  _hub_slug="" _hub_n=0
  while (( $# )); do
    case "$1" in
      -r | --repo)
        _hub_slug=$(_hub_norm_slug "${2:-}") || {
          print -u2 "${funcstack[2]}: -r needs a repo: owner/name, a GitHub URL or a git remote"
          return 1
        }
        shift 2; (( _hub_n += 2 )) ;;
      --repo=*)
        _hub_slug=$(_hub_norm_slug "${1#--repo=}") || {
          print -u2 "${funcstack[2]}: --repo needs owner/name, a GitHub URL or a git remote"
          return 1
        }
        shift; (( _hub_n += 1 )) ;;
      --) (( _hub_n += 1 )); return 0 ;;
      -?*) print -u2 "${funcstack[2]}: unknown option $1 (text starting with - goes after --)"; return 1 ;;
      *) return 0 ;;
    esac
  done
}

# did "Reviewed the rollout plan with Priya"
# did -r webtize/payments-api "Paired with Sid on the retry bug"
# Logs work you did yourself as an already-closed bead, so the daily report
# (`hub report`) sees it. Tagged repo:<owner>/<name> from -r, or else from the
# git repo you're in; outside a repo and without -r it gets no repo label.
did() {
  local _hub_slug _hub_n labels=manual slug id
  _hub_repo_opt "$@" || return
  shift $_hub_n
  if (( ! $# )); then
    print -u2 'usage: did [-r owner/name] "what you did"   — logs a closed bead in the hub'
    return 1
  fi
  slug=${_hub_slug:-$(_hub_repo_slug)}
  [[ -n "$slug" ]] && labels+=",repo:$slug"
  # --title=, not a positional title: bd refuses a positional title that starts
  # with "-" (it looks like a flag), e.g. did -- "-5% p95 latency".
  id=$(bdh create --title="$*" -t task -l "$labels" --silent) || return
  bdh close "$id" -r done > /dev/null || return
  print -r -- "logged $id${slug:+ ($slug)}"
}

# todo "Chase IT about the Teams webhook"   — add a to-do only you can do
# todo -r webtize/x "Ask Sid for the staging creds"
# todo                                       — list your open to-dos
# Labelled `human`, which the dispatcher never picks up. Repo as for did.
todo() {
  local _hub_slug _hub_n labels=human slug id
  _hub_repo_opt "$@" || return
  shift $_hub_n
  if (( ! $# )); then
    bdh list -l human
    return
  fi
  slug=${_hub_slug:-$(_hub_repo_slug)}
  [[ -n "$slug" ]] && labels+=",repo:$slug"
  id=$(bdh create --title="$*" -t task -l "$labels" -a "$(git config --global user.name)" --silent) || return
  print -r -- "added $id${slug:+ ($slug)}"
}

# Homebrew/AUR install bd's own completion; give bdh the same one.
(( $+functions[compdef] )) && compdef bdh=bd
