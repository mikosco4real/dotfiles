dofile(vim.g.base46_cache .. "mason")

require("mason").setup({
    PATH = "skip",
    ui = {
        icons = {
            package_pending = " ",
            package_installed = " ",
            package_uninstalled = " ",
        },
    },
    max_concurrent_installers = 10,
})

-- NvChad's `ui` plugin registers the :MasonInstallAll user command that
-- pulls everything from chadrc.mason.pkgs plus auto-detected LSPs and
-- formatters. Run it once after first launch:  :MasonInstallAll
