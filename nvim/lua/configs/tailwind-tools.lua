-- tailwind-tools internally calls `require('lspconfig').xxx`, which nvim-
-- lspconfig now flags with `vim.deprecate`. Silence just that one warning
-- while the plugin sets up — restore immediately after.

local orig_deprecate = vim.deprecate
vim.deprecate = function() end

local ok, err = pcall(function()
    require("tailwind-tools").setup({})
end)

vim.deprecate = orig_deprecate

if not ok then
    vim.notify("tailwind-tools setup failed: " .. tostring(err), vim.log.levels.WARN)
end
