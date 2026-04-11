local ts, available_langs = nil, nil

local gid = vim.api.nvim_create_augroup("TreesitterAutoInstall", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = gid,
    callback = function(ev)
        ts = require("nvim-treesitter")

        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang then
            return
        end

        available_langs = available_langs or ts.get_available()
        if not vim.tbl_contains(available_langs, lang) then
            return
        end

        local start = function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
                vim.treesitter.start(ev.buf)
            end
        end

        if vim.tbl_contains(ts.get_installed(), lang) then
            start()
        else
            ts.install(lang):await(start)
        end
    end,
})

return {
    ---@type LazyPluginSpec
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
                branch = "main",
            },
        },
        opts = {
            install_dir = vim.fn.stdpath("state") .. "/site",
        },
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
    },
}
