---@type LazyPluginSpec
return {
    "lewis6991/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile", "FileReadPre" },
    config = function()
        require("colorizer").setup()
    end,
}
