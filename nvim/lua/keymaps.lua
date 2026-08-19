-- Full NvChad keymap set, ported verbatim from nvchad/mappings.lua, plus
-- the personal overrides that previously lived in lua/mappings.lua.
--
-- Anything calling require("nvchad.term") / require("nvchad.tabufline") /
-- require("nvchad.themes") still works because we keep the NvChad `ui`
-- plugin loaded (see lua/plugins.lua).

local map = vim.keymap.set

-- ── Insert-mode line nav ────────────────────────────────────────────
map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

-- ── Window navigation ───────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

-- ── General ─────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

-- :Format refuses to touch a buffer holding template markers (see
-- configs/conform.lua); :Format! overrides. The x-mode map uses `:` rather than
-- `<cmd>` so the visual range is passed through.
map("n", "<leader>fm", "<cmd>Format<CR>", { desc = "general format file" })
map("x", "<leader>fm", ":Format<CR>", { desc = "general format selection", silent = true })

-- ── LSP-global (per-buffer LSP keymaps live in lua/lsp.lua) ─────────
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- ── Tabufline ───────────────────────────────────────────────────────
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<tab>", function()
    require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })
map("n", "<S-tab>", function()
    require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })
map("n", "<leader>x", function()
    require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- ── Comment ─────────────────────────────────────────────────────────
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- ── nvim-tree ───────────────────────────────────────────────────────
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- ── Telescope ───────────────────────────────────────────────────────
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

map("n", "<leader>th", function()
    require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "telescope find all files" }
)

-- ── Terminal ────────────────────────────────────────────────────────
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- <leader>tt, not <leader>h: <leader>h is the gitsigns hunk prefix now, and a
-- direct map there would swallow every <leader>h* binding for `timeoutlen`.
-- <leader>th is already the theme picker, so tt is the free slot.
map("n", "<leader>tt", function()
    require("nvchad.term").new({ pos = "sp" })
end, { desc = "terminal new horizontal term" })

map("n", "<leader>v", function()
    require("nvchad.term").new({ pos = "vsp" })
end, { desc = "terminal new vertical term" })

map({ "n", "t" }, "<A-v>", function()
    require("nvchad.term").toggle({ pos = "vsp", id = "vtoggleTerm" })
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
    require("nvchad.term").toggle({ pos = "sp", id = "htoggleTerm" })
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
    require("nvchad.term").toggle({ pos = "float", id = "floatTerm" })
end, { desc = "terminal toggle floating term" })

-- ── Git ─────────────────────────────────────────────────────────────
-- Hunk-level bindings (<leader>h*, ]h / [h, ih) are buffer-local and live in
-- configs/gitsigns.lua's on_attach, so they only exist inside a repo.

-- nvchad.term takes a `cmd`, so lazygit needs no plugin. Same id both times, so
-- <leader>gg toggles it shut again.
map({ "n", "t" }, "<leader>gg", function()
    require("nvchad.term").toggle({ pos = "float", id = "lazygit", cmd = "lazygit" })
end, { desc = "git lazygit" })

map("n", "<leader>gb", function()
    require("gitsigns").blame_line({ full = true })
end, { desc = "git blame line (popup)" })

map("n", "<leader>gB", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "git blame inline toggle" })
map("n", "<leader>gL", "<cmd>Gitsigns blame<CR>", { desc = "git blame full file" })

map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "git status" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "git commits" })

map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "git diff working tree" })
map("n", "<leader>gD", "<cmd>DiffviewOpen origin/HEAD...HEAD<CR>", { desc = "git diff vs origin/HEAD" })
map("n", "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "git history (this file)" })
map("n", "<leader>gF", "<cmd>DiffviewFileHistory<CR>", { desc = "git history (repo)" })
map("n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "git close diffview" })

-- :GitLink copies a permalink, :GitLink! opens it. `:` not `<cmd>` in x mode so
-- the selection becomes a line range in the link.
map("n", "<leader>gy", "<cmd>GitLink<CR>", { desc = "git copy permalink" })
map("x", "<leader>gy", ":GitLink<CR>", { desc = "git copy permalink", silent = true })
map("n", "<leader>gY", "<cmd>GitLink!<CR>", { desc = "git open permalink" })
map("x", "<leader>gY", ":GitLink!<CR>", { desc = "git open permalink", silent = true })

-- ── Diagnostics / TODOs ─────────────────────────────────────────────
-- <leader>d, not trouble's upstream <leader>x — <leader>x closes a buffer here.
map("n", "<leader>dt", "<cmd>Trouble diagnostics toggle<CR>", { desc = "diagnostics list (repo)" })
map("n", "<leader>dT", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "diagnostics list (buffer)" })
map("n", "<leader>dq", "<cmd>Trouble qflist toggle<CR>", { desc = "quickfix list" })
map("n", "<leader>dl", "<cmd>Trouble loclist toggle<CR>", { desc = "location list" })
map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "telescope find todos" })

map("n", "]t", function()
    require("todo-comments").jump_next()
end, { desc = "next todo comment" })

map("n", "[t", function()
    require("todo-comments").jump_prev()
end, { desc = "prev todo comment" })

-- ── which-key ───────────────────────────────────────────────────────
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })
map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

-- ── Personal overrides ──────────────────────────────────────────────
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
