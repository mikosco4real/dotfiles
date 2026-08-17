#!/usr/bin/env bash
# Build the default dev layout for a tmux session:
#   IDE (nvim .) | GIT (lazygit) | Terminal | Logs | Claude (claude)
# Idempotent: bails if the session already has more than one window.

set -euo pipefail

session="${1:-$(tmux display-message -p '#S')}"

window_count=$(tmux list-windows -t "$session" -F '#{window_id}' | wc -l | tr -d ' ')
if [ "$window_count" -gt 1 ]; then
    exit 0
fi

start_dir=$(tmux display-message -t "$session" -p '#{session_path}')

tmux rename-window -t "$session:" IDE
tmux send-keys -t "$session:IDE" 'nvim .' Enter

tmux new-window -t "$session:" -n GIT -c "$start_dir"
tmux send-keys -t "$session:GIT" 'lazygit' Enter

tmux new-window -t "$session:" -n Terminal -c "$start_dir"
tmux new-window -t "$session:" -n Logs -c "$start_dir"

tmux new-window -t "$session:" -n Claude -c "$start_dir"
tmux send-keys -t "$session:Claude" 'claude' Enter

tmux select-window -t "$session:IDE"
