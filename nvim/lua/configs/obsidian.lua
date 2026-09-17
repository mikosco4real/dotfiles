-- obsidian.nvim (obsidian-nvim/obsidian.nvim — the maintained community fork).
--
-- Since v3.16.x this registers as a language server (obsidian-ls) over the
-- vault, so `gd`, `gr`, rename, folding, completion and code actions all come
-- from the normal LSP path rather than plugin-specific commands. That is also
-- why there is no completion block below — the LSP provides it.
--
-- Two things to keep in mind:
--  1. ui.enabled = false — obsidian.nvim's own renderer clashes with
--     render-markdown.nvim. Exactly one of them may own the display.
--  2. The plugin does NOT read .obsidian/app.json, so the link settings below
--     must be kept in step with Obsidian's own settings by hand. They match:
--       newLinkFormat: shortest  -> link.format = "shortest"
--       useMarkdownLinks: false  -> link.style  = "wiki"
--       attachmentFolderPath     -> attachments.folder

-- The vault is not in the same place on every machine, so its path is resolved
-- at startup instead of hardcoded. nvim/ lives outside chezmoi's source state
-- (see CLAUDE.md), so this cannot be templated -- it has to be a runtime lookup.
--
--   1. $OBSIDIAN_VAULT, exported from ~/.config/zsh/local.zsh -- the per-machine
--      file chezmoi seeds once and never overwrites.
--   2. failing that, the first conventional location that actually exists.
--
-- If nothing resolves, setup is skipped entirely rather than registering a
-- workspace pointing at a directory that is not there.
local function resolve_vault()
    local from_env = vim.env.OBSIDIAN_VAULT
    if from_env and from_env ~= "" then
        local path = vim.fn.expand(from_env)
        if vim.fn.isdirectory(path) == 1 then
            return path
        end
        vim.notify("$OBSIDIAN_VAULT is not a directory: " .. path, vim.log.levels.WARN)
    end

    for _, candidate in ipairs({
        "~/Documents/Obsidian",
        "~/Obsidian",
        "~/Notes",
        "~/Library/Mobile Documents/iCloud~md~obsidian/Documents",
    }) do
        local path = vim.fn.expand(candidate)
        if vim.fn.isdirectory(path) == 1 then
            return path
        end
    end

    return nil
end

local vault = resolve_vault()
if not vault then
    return
end

-- Only register sub-workspaces that exist, so a vault laid out differently on
-- another machine does not produce startup errors.
local workspaces = { { name = "vault", path = vault } }
for _, ws in ipairs({
    { name = "work", subdir = "20 Work" },
    { name = "personal", subdir = "30 Personal" },
}) do
    local path = vault .. "/" .. ws.subdir
    if vim.fn.isdirectory(path) == 1 then
        workspaces[#workspaces + 1] = { name = ws.name, path = path }
    end
end

require("obsidian").setup({
    legacy_commands = false,

    workspaces = workspaces,

    notes_subdir = "00 Inbox",
    new_notes_location = "notes_subdir",

    daily_notes = {
        -- daily_notes.folder does NOT expand strftime tokens, so the year lives
        -- in date_format instead. This mirrors Obsidian's own daily-notes.json
        -- ("folder": "10 Journal", "format": "YYYY/YYYY-MM-DD") so both apps
        -- land on the same path.
        folder = "10 Journal",
        date_format = "%Y/%Y-%m-%d",
        template = "Daily.md",
    },

    templates = {
        folder = "90 Meta/Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
    },

    attachments = {
        folder = "90 Meta/Attachments",
    },

    link = {
        style = "wiki",
        format = "shortest",
    },

    -- Filenames stay human-readable; the zk-style id lives in frontmatter,
    -- which is the convention the migrated notes already use.
    note_id_func = function(title)
        if title ~= nil and title ~= "" then
            return title
        end
        return tostring(os.time())
    end,

    -- Preserve every existing frontmatter key (id, type, context, status…) so
    -- the Bases in 90 Meta/Bases keep working when nvim rewrites a note.
    frontmatter = {
        func = function(note)
            local out = { id = note.id, aliases = note.aliases, tags = note.tags }
            if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                for k, v in pairs(note.metadata) do
                    out[k] = v
                end
            end
            return out
        end,
    },

    checkbox = {
        order = { " ", "x" },
    },

    -- render-markdown.nvim owns the display.
    ui = { enabled = false },

    picker = { name = "telescope.nvim" },
})
