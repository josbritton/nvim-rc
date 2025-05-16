---@type LazyPluginSpec
return {
    "laytan/cloak.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        {
            "<leader>v",
            "<Cmd>CloakToggle<CR>",
            desc = "Cloak: toggle [v]isibility",
        },
    },
    opts = {
        cloak_on_leave = true,
        try_all_patterns = false, -- break after first line pattern match
        patterns = {
            -- replace: lua gsub pattern to substitute on match, referencing match groups,
            -- the rest of the match is filled with the replacement char
            {
                file_pattern = { ".env*", "secret*.tfvars" },
                cloak_pattern = "(=%s*)%S+",
                replace = "%1",
            },
            {
                file_pattern = { "*/secrets/*.yaml", "*/secret/*.yaml" },
                cloak_pattern = { "(:%s*)%S+", "(-%s*)%S+" },
                replace = "%1",
            },
        },
    },
}
