---@type LazyPluginSpec
return {
    "folke/which-key.nvim",
    event = "VimEnter",
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        delay = 0, -- also see vim.opt.timeoutlen
        disable = {
            ft = {},
            bt = {},
        },
        expand = 1, -- expand groups with >= n items
        icons = {
            keys = {
                Up = "Up ",
                Down = "Down ",
                Left = "Left ",
                Right = "Right ",
                C = "Ctrl-",
                M = "Alt-",
                D = "Cmd-",
                S = "Shift-",
                CR = "Enter ",
                Esc = "Esc ",
                ScrollWheelDown = "ScrollDown ",
                ScrollWheelUp = "ScrollUp ",
                NL = "*Enter ",
                BS = "Backspace ",
                Space = "Space ",
                Tab = "Tab ",
                F1 = "F1",
                F2 = "F2",
                F3 = "F3",
                F4 = "F4",
                F5 = "F5",
                F6 = "F6",
                F7 = "F7",
                F8 = "F8",
                F9 = "F9",
                F10 = "F10",
                F11 = "F11",
                F12 = "F12",
            },
        },
        triggers = {}, -- do not automatically show key help, only on keymap
        spec = {
            { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
            {
                "<leader>d",
                group = "[D]ocument",
            },
            { "<leader>r", group = "[R]ename" },
            {
                "<leader>s",
                group = "[S]earch and Replace Item Under Cursor",
                ---@type wk.Icon
                icon = {
                    icon = " ",
                    color = "green",
                },
            },
            { "<leader>w", group = "[W]orkspace" },
            { "<leader>t", group = "[T]oggle" },
            { "<leader>p", group = "[P]roject" },
            { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
            ---@type wk.Mapping
            {
                "<leader>g",
                group = "[G]it",
                ---@type wk.Icon
                icon = {
                    cat = "filetype",
                    name = "git",
                },
            },
            -- ---@type wk.Mapping
            -- {
            --     "d",
            --     desc = "Create [D]irectory",
            --     condition = function()
            --         if vim.bo.fil
            --     end
            -- },
            -- {
            --     "<C-J>",
            --     desc = "[J]ump to Tmux session (external)",
            -- },
        },
        win = {
            wo = {
                winblend = 10, -- % transparency
            },
        },
    },
    keys = {
        {
            "<C-_>", -- <C-/>
            function()
                ---@type wk.Filter
                require("which-key").show({
                    global = false,
                    expand = false,
                })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
}
