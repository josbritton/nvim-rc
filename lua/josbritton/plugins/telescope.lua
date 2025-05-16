return {
    ---@type LazyPluginSpec
    {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        dependencies = {
            -- build and make available C port of fzf for telescope
            -- (does not require fzf to be installed on the system)
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable("make") == 1
                        and (
                            vim.fn.executable("gcc") == 1
                            or vim.fn.executable("clang") == 1
                        )
                end,
            },
            -- note: will use LSP and treesitter features
        },
        keys = {
            -- {
            --     "<leader>?",
            --     "<cmd>Telescope oldfiles<CR>",
            --     desc = "[?] Find recently opened files",
            -- },
            {
                "<C-k>",
                nil,
                desc = "[ ] Find hidden buffers",
            },
            {
                "<leader>/",
                function()
                    -- you can pass additional configuration to telescope to change theme, layout, etc.
                    require("telescope.builtin").current_buffer_fuzzy_find(
                        require("telescope.themes").get_dropdown({
                            winblend = 10,
                            previewer = false,
                        })
                    )
                end,
                desc = "[/] Fuzzily search in current buffer",
            },
            {
                "<C-p>",
                "<cmd>Telescope find_files hidden=true<CR>",
                desc = "Search [P]roject by filename",
            },
            {
                "<leader>ps",
                "<cmd>Telescope live_grep<CR>",
                desc = "Search [P]roject by Grep [S]tring",
            },
            {
                "<leader>q",
                "<cmd>Telescope diagnostics<CR>",
                mode = { "n" },
                desc = "Search Diagnostics",
            },
        },
        cmd = {
            "Telescope",
        },
        config = function()
            vim.opt_local.winborder = ""

            local actions = require("telescope.actions")

            local pickers_new = require("telescope.pickers").new
            local new_finder_t = require("telescope.finders").new_table
            local make_entry_from_buffer = require("telescope.make_entry").gen_from_buffer
            local get_generic_fuzzy_sorter =
                require("telescope.sorters").get_generic_fuzzy_sorter

            local theme_opts = require("telescope.themes").get_dropdown({
                bufnr_width = nil, -- set it dynamically
                cwd_only = false,
                sort_lastused = true,
                sort_mru = false,
            })

            ---@return nil
            local function hidden_buffers()
                local opts = theme_opts

                ---@param bufnr integer
                ---@return boolean
                local bufnrs = vim.tbl_filter(function(bufnr)
                    -- ignore invalid buffer ids
                    if 1 ~= vim.fn.buflisted(bufnr) then
                        return false
                    end
                    -- ignore buffers that are already open
                    if vim.fn.bufwinnr(bufnr) > -1 then
                        return false
                    end

                    return true
                end, vim.api.nvim_list_bufs())

                if not next(bufnrs) then
                    Notify.info(
                        "No buffers found with the provided options",
                        { title = "builtin.buffers" }
                    )
                    return
                end

                if opts.sort_mru then
                    table.sort(bufnrs, function(a, b)
                        return vim.fn.getbufinfo(a)[1].lastused
                            > vim.fn.getbufinfo(b)[1].lastused
                    end)
                end

                local buffers = {}
                local default_selection_idx = 1
                for _i, bufnr in ipairs(bufnrs) do
                    local flag = bufnr == vim.fn.bufnr("") and "%"
                        or (bufnr == vim.fn.bufnr("#") and "#" or " ")

                    local element = {
                        bufnr = bufnr,
                        flag = flag,
                        info = vim.fn.getbufinfo(bufnr)[1],
                    }

                    if opts.sort_lastused and (flag == "#" or flag == "%") then
                        local idx = (
                            (buffers[1] ~= nil and buffers[1].flag == "%") and 2 or 1
                        )
                        table.insert(buffers, idx, element)
                    else
                        table.insert(buffers, element)
                    end
                end

                if not opts.bufnr_width then
                    local max_bufnr = math.max(unpack(bufnrs))
                    opts.bufnr_width = #tostring(max_bufnr)
                end

                pickers_new(opts, {
                    prompt_title = "Hidden Buffers",
                    finder = new_finder_t({
                        results = buffers,
                        entry_maker = make_entry_from_buffer(opts),
                    }),
                    push_tagstack_on_edit = true,
                    previewer = false,
                    sorter = get_generic_fuzzy_sorter(opts),
                    default_selection_index = default_selection_idx,
                    attach_mappings = function(_, map)
                        -- close(delete) open buffer under cursor without closing picker
                        map(
                            { "i" },
                            -- bug: inserts leader character in input if leader character is a printable key
                            "<leader>cc",
                            actions.delete_buffer + actions.move_to_top
                        )
                        return true
                    end,
                }):find()
            end

            require("telescope").setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-u>"] = false, -- half-screen movement (up)
                            ["<C-d>"] = false, -- half-screen movement (down)
                            ["<esc>"] = actions.close, -- map ESC to quit in insert mode
                        },
                    },
                },
                pickers = {
                    find_files = {
                        -- default picker ignores fd ignore file
                        find_command = { "fd", "--type", "f" },
                        push_tagstack_on_edit = true,
                    },
                    live_grep = {
                        push_tagstack_on_edit = true,
                    },
                },
            })

            vim.keymap.set(
                "n",
                "<C-k>",
                vim.schedule_wrap(hidden_buffers),
                { desc = "[ ] Find hidden buffers" }
            )

            -- fzf *native*
            require("telescope").load_extension("fzf")
        end,
    },
    { "nvim-lua/plenary.nvim" },
    { "nvim-tree/nvim-web-devicons" },
}
