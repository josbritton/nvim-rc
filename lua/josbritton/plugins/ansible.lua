---@type LazyPluginSpec
return {
    "pearofducks/ansible-vim",
    dependencies = {
        "nvim-treesitter",
    },
    ft = { "ansible", "jinja2" },
    lazy = true,
    config = function()
        local ts = require("nvim-treesitter")

        local t = vim.tbl_filter(function(lang)
            return not vim.tbl_contains(ts.get_installed(), lang)
        end, { "jinja", "yaml" })

        ts.install(t):await(require("ansible").setup)
    end,
}
