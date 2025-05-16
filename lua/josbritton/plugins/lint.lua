---@type LazyPluginSpec
return {
    "mfussenegger/nvim-lint",
    dependencies = {
        "williamboman/mason.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
    init = function()
        vim.g.linter_initialized = false
    end,
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
            bash = { "shellcheck" },
            sh = { "shellcheck" },
            markdown = { "markdownlint" },
            yaml = { "yamllint" },
        }

        local gid = vim.api.nvim_create_augroup("lint", { clear = true })
        vim.api.nvim_create_autocmd({ "FileType", "BufWritePost", "CursorHold" }, {
            group = gid,
            callback = function(args)
                if
                    vim.api.nvim_get_option_value(
                        "buftype",
                        { scope = "local", buf = args.buf }
                    ) ~= "nofile"
                then
                    lint.try_lint()
                end
            end,
        })
        vim.g.linter_initialized = true

        -- try once on init
        lint.try_lint()
    end,
}
