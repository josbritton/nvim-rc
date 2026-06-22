---@type LazyPluginSpec
return {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    ---@type lazydev.Config
    opts = {
        library = {
            "lazy.nvim",
            "lazydev.nvim",
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    },
}
