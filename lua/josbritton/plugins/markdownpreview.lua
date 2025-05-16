---@type LazyPluginSpec
return {
    "iamcco/markdown-preview.nvim",
    build = "cd app && yarn install",
    ft = "markdown",
    cond = function()
        return vim.fn.executable("yarn") == 1
    end,
}
