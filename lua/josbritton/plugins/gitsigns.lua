return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local api = vim.api
        local gitsigns = require("gitsigns")
        local status = require("gitsigns.status")

        local redrawstatus = vim.schedule_wrap(function()
            vim.api.nvim__redraw({ statusline = true })
        end)

        -- override status update calls to redraw the statusline directly
        local gs_update = status.update
        ---@diagnostic disable-next-line: duplicate-set-field
        status.update = function(self, bufnr, status)
            if not api.nvim_buf_is_loaded(bufnr) then
                return
            end
            gs_update(self, bufnr, status)
            redrawstatus()
        end

        local gs_clear = status.clear
        ---@diagnostic disable-next-line: duplicate-set-field
        status.clear = function(self, bufnr)
            if not api.nvim_buf_is_loaded(bufnr) then
                return
            end
            gs_clear(self, bufnr)
            redrawstatus()
        end

        local function on_attach(bufnr)
            ---@param mode string|string[]
            ---@param l string
            ---@param r string|function
            ---@param opts? vim.keymap.set.Opts
            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Git: [h]unk [s]tage" })

            map("v", "<leader>hs", function()
                -- partial-hunk selections only support line-by-line ranges
                gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Git: [h]unk [s]tage" })

            map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Git: [h]unk [r]eset" })
            map("v", "<leader>hr", function()
                -- partial-hunk selections only support line-by-line ranges
                gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Git: [h]unk [r]eset" })

            map(
                { "n", "v" },
                "<leader>hS",
                gitsigns.stage_buffer,
                { desc = "Git: [h]unk [S]tage BUFFER" }
            )

            map(
                { "n", "v" },
                "<leader>hR",
                gitsigns.reset_buffer,
                { desc = "Git: [h]unk [R]eset BUFFER" }
            )

            map(
                { "n", "v" },
                "<leader>hp",
                gitsigns.preview_hunk_inline,
                { desc = "Git: [h]unk [p]review" }
            )

            map(
                { "n", "v" },
                "<leader>tb",
                gitsigns.toggle_current_line_blame,
                { desc = "Git: [T]oggle [b]lame line" }
            )

            map(
                { "o", "x", "v" },
                "ih",
                gitsigns.select_hunk,
                { desc = "Select git hunk from text object" }
            )

            ---@type Gitsigns.NavOpts
            ---@diagnostic disable-next-line: missing-fields
            local nav_opts = {
                wrap = false,
                navigation_message = true,
                preview = false,
                greedy = true,
                target = "unstaged",
            }

            local next_hunk = function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    vim.schedule(function()
                        gitsigns.nav_hunk("next", nav_opts)
                    end)
                end
            end
            map("n", "]c", next_hunk, { desc = "Jump to next hunk" })
            map("n", "<Tab>", next_hunk, { desc = "Jump to next hunk", noremap = true })

            local prev_hunk = function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    vim.schedule(function()
                        gitsigns.nav_hunk("prev", nav_opts)
                    end)
                end
            end
            map("n", "[c", prev_hunk, { desc = "Jump to previous hunk" })
            map(
                "n",
                "<S-Tab>",
                prev_hunk,
                { desc = "Jump to previous hunk", noremap = true }
            )

            map("n", "<leader>hb", function()
                gitsigns.blame_line({ full = true })
            end)
        end

        gitsigns.setup({
            max_file_length = 100000,
            signs = {
                add = { text = "+", show_count = false },
                change = { text = "~", show_count = false },
                delete = { text = "-", show_count = false },
                topdelete = { text = "‾", show_count = false },
                changedelete = { text = "~", show_count = false },
                untracked = { text = "┆", show_count = false },
            },
            status_formatter = function(_)
                return ""
            end,
            on_attach = on_attach,
            preview_config = {
                border = "rounded",
            },
            current_line_blame = false,
            update_debounce = 50,
            attach_to_untracked = true,
            word_diff = false,
        })
    end,
}
