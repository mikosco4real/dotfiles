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

local vault = vim.fn.expand("~/Documents/Obsidian")

require("obsidian").setup({
    legacy_commands = false,

    workspaces = {
        { name = "vault", path = vault },
        { name = "work", path = vault .. "/20 Work" },
        { name = "personal", path = vault .. "/30 Personal" },
    },

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
