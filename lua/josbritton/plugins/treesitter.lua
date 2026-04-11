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
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
    },
}
