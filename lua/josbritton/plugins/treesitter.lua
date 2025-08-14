return {
    ---@type LazyPluginSpec
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPost", "BufNewFile", "FileReadPost" },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
            max_lines = 1,
        },
    },
    ---@type LazyPluginSpec
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        build = ":TSUpdate",
        event = { "BufReadPre", "BufNewFile", "FileReadPre" },
        cmd = {
            -- :h nvim-treesitter-commands
            "TSInstall",
            "TSInstallSync",
            "TSInstallInfo",
            "TSUpdate",
            "TSUpdateSync",
            "TSUninstall",
            "TSBufEnable",
            "TSBufDisable",
            "TSBufToggle",
            "TSEnable",
            "TSDisable",
            "TSToggle",
            "TSModuleInfo",
            "TSEditQuery",
            "TSEditQueryUserAfter",

            "TSTextobjectSwapNext",
            "TSTextobjectSwapPrevious",
            "TSTextobjectGotoNextStart",
            "TSTextobjectGotoNextEnd",
            "TSTextobjectGotoPreviousStart",
            "TSTextobjectGotoPreviousEnd",
            "TSTextobjectRepeatLastMove",
            "TSTextobjectRepeatLastMoveOpposite",
            "TSTextobjectRepeatLastMoveNext",
            "TSTextobjectRepeatLastMovePrevious",
            "TSTextobjectBuiltinf",
            "TSTextobjectBuiltinF",
            "TSTextobjectBuiltint",
            "TSTextobjectBuiltinT",
            "TSTextobjectPeekDefinitionCode",
            "TSTextobjectSelect",
        },
        main = "nvim-treesitter.configs",
        config = true,
        opts = {
            ensure_installed = {
                "c",
                "cpp",
                "go",
                "lua",
                "python",
                "rust",
                "tsx",
                "javascript",
                "typescript",
                "vimdoc",
                "vim",
                "bash",
                "markdown",
            },
            auto_install = true,
            sync_install = false,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = { "ruby" },
            },
            indent = {
                enable = true,
                disable = { "ruby", "yaml" },
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    -- init_selection = "<c-space>",
                    -- node_incremental = "<c-space>",
                    scope_incremental = "<c-s>",
                    node_decremental = "<M-space>",
                },
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- automatically jump forward to textobj, similar to targets.vim
                    keymaps = {
                        -- you can use the capture groups defined in textobjects.scm
                        ["aa"] = "@parameter.outer",
                        ["ia"] = "@parameter.inner",
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]]"] = "@class.outer",
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                        ["]["] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[["] = "@class.outer",
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                        ["[]"] = "@class.outer",
                    },
                },
                swap = {
                    enable = true,
                    swap_next = {
                        ["<leader>a"] = "@parameter.inner",
                    },
                    swap_previous = {
                        ["<leader>A"] = "@parameter.inner",
                    },
                },
            },
        },
    },
}
