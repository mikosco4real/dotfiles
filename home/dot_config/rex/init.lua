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

-- Dev layout, ported from ~/.config/tmux/scripts/setup-session.sh: one tab each
-- for IDE (nvim .), GIT (lazygit), Terminal, Logs and Claude (claude), all in
-- one directory. Programs are typed into a shell, as tmux's send-keys did, so
-- quitting nvim or lazygit leaves the tab open at a prompt.
local TERMINAL = "com.superlogical.terminal"
local DEV_TABS = {
    { label = "IDE", run = "nvim ." },
    { label = "GIT", run = "lazygit" },
    { label = "Terminal" },
    { label = "Logs" },
    { label = "Claude", run = "claude" },
}

-- A pane's directory: what its program last reported (a file:// URL from OSC 7,
-- or a plain path), else the foreground process's actual cwd, else $HOME.
-- zsh here reports nothing, so the process lookup is the usual path.
local function pane_dir(block_id)
    if block_id then
        local reply = rex.block.call(TERMINAL, "pwd", { block_id = block_id })
        local dir = reply and reply.pwd
        if dir and dir ~= "" then
            dir = dir:gsub("^file://[^/]*", "")
            dir = dir:gsub("%%(%x%x)", function(hex)
                return string.char(tonumber(hex, 16))
            end)
            return dir
        end
        local proc = rex.block.call(TERMINAL, "process", { block_id = block_id })
        local cwd = proc and proc.foreground and proc.foreground.cwd
        if cwd and cwd ~= "" then
            return cwd
        end
    end
    return os.getenv("HOME")
end

local function expand_home(dir)
    return (dir:gsub("^~", os.getenv("HOME")))
end

local function tab_layout(dir, tab)
    local options = { cwd = dir }
    if tab.run then
        options.initial_input = tab.run .. "\r"
    end
    return rex.layout.block({ flavor = "com.superlogical.terminal.shell", options = options })
end

rex.action({
    name = "dev_session",
    title = "New Dev Session",
    description = "Create a session with IDE, GIT, Terminal, Logs and Claude tabs in the current pane's directory.",
    category = "Sessions",
    keywords = "tmux setup-session layout workspace nvim lazygit claude",
    args = { dir = "string?", show = "boolean?" },
    run = function(ctx, args)
        args = args or {}
        local dir = args.dir and expand_home(args.dir) or pane_dir(ctx.block_id)
        local windows = {}
        for i, tab in ipairs(DEV_TABS) do
            windows[i] = { window_label = tab.label, layout = tab_layout(dir, tab) }
        end
        local created, err = rex.call("session.create", {
            label = dir:match("([^/]+)/*$") or dir,
            initial_windows = windows,
        })
        if not created then
            error("New Dev Session: " .. tostring(err))
        end
        -- session.create leaves the last tab active; start on IDE, as tmux did.
        -- Showing the session on IDE (below) covers the usual case. The server only
        -- takes session calls for a session the caller is attached to, and only
        -- rex do scripts can attach, so from a key binding these two calls are
        -- best-effort and fail quietly.
        local sid, ide = created.session_id, created.initial_windows[1].window_id
        pcall(rex.session.attach, { session_id = sid })
        rex.session.focus_window({ session_id = sid, window_id = ide })
        if args.show ~= false then
            pcall(rex.client.queue, "session.select", { session_id = sid, window_id = ide })
        end
        return { session_id = sid, dir = dir }
    end,
})

rex.action({
    name = "dev_layout",
    title = "Dev Layout",
    description = "Turn a one-tab session into IDE, GIT, Terminal, Logs and Claude tabs, like tmux's prefix L.",
    category = "Sessions",
    keywords = "tmux setup-session layout workspace nvim lazygit claude",
    run = function(ctx)
        local view, err = rex.session.view({})
        if not view then
            error("Dev Layout: " .. tostring(err))
        end
        -- Like setup-session.sh, leave a session that already has several tabs alone.
        if #view.windows > 1 then
            return { skipped = "the session already has more than one tab" }
        end
        local first = view.windows[1]
        local block = first.focused_block_id or ctx.block_id
        local dir = pane_dir(block)
        rex.session.set_window_label({ window_id = first.window_id, label = DEV_TABS[1].label })
        rex.block.call(TERMINAL, "write", { block_id = block, data = DEV_TABS[1].run .. "\r" })
        for i = 2, #DEV_TABS do
            local tab = DEV_TABS[i]
            rex.session.new_window({ window_label = tab.label, layout = tab_layout(dir, tab), focus = false })
        end
        return { dir = dir }
    end,
})

rex.bind("ctrl+b>shift+l", "dev_layout") -- tmux.conf:57, bind L
rex.bind("ctrl+b>shift+n", "dev_session")
