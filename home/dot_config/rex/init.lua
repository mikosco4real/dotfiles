-- Rex keybindings, migrated from tmux, Ghostty and kitty.
-- Managed by chezmoi (home/dot_config/rex/init.lua); ~/.config/rex/init.lua is a live symlink.
-- Validate: rex config check. Apply: Reload Config in Rex.

-- tmux (~/.config/tmux/tmux.conf), prefix ctrl+b
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" }) -- tmux.conf:31
rex.bind("ctrl+b>-", "pane.split", { direction = "down" }) -- tmux.conf:32
rex.bind("ctrl+b>h", "pane.focus", { direction = "left" }) -- tmux.conf:42
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" }) -- tmux.conf:43
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" }) -- tmux.conf:44
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" }) -- tmux.conf:45
-- ctrl+b now only starts a sequence; press it twice to send it to the program.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
-- Session picker on the tmux prefix + s, as in tmux (cmd+k still opens it too).
rex.bind("ctrl+b>s", "session.switch")

-- Ghostty (~/.config/ghostty/config.darwin)
rex.bind("cmd+9", "client.tab.goto", { index = 9 }) -- config.darwin:29
rex.bind("shift+cmd+k", "com.superlogical.terminal.clear") -- config.darwin:43

-- kitty (~/.config/kitty/kitty.conf)
rex.bind("cmd+left", "pane.send_key", { key = "ctrl+a" }) -- kitty.conf:116
rex.bind("cmd+right", "pane.send_key", { key = "ctrl+e" }) -- kitty.conf:117
