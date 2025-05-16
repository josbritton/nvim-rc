local conf = {
    "tamago324/lir-git-status.nvim",
    dependencies = {
        "JosBritton/lir.nvim",
    },
    lazy = true,
    keys = {
        { "<leader>pv", nil, desc = "O[p]en File Explorer [V]iew" },
    },
    config = function()
        require("nvim-web-devicons").set_icon({
            lir_folder_icon = {
                icon = "",
                color = "#7ebae4",
                name = "LirFolderNode",
            },
        })

        local lir = require("lir")
        local actions = require("lir.actions")
        local noop = function() end

        local yank_rel_filename = function()
            local ctx = lir.get_context()
            local path = (Statusline.bufname() or "") .. ctx:current_value()
            vim.fn.setreg(vim.v.register, path)
            print("Yank file: " .. path)
        end

        ---@param stage boolean
        local function git_stage_unstage(stage)
            local bufnr = vim.fn.bufnr("%")

            local ctx = lir.get_context()
            local path = ctx.dir .. ctx:current_value()
            local short_path = (Statusline.bufname() or "") .. ctx:current_value()

            local arg = stage and { "git", "add" } or { "git", "restore", "--staged" }
            table.insert(arg, path)

            vim.system(arg, { text = true }, function(res)
                if res.code > 0 then
                    Notify.error(
                        "Git error\n" .. (res.stderr or ""),
                        { title = "Git error" }
                    )
                    return
                end

                local buf_call = vim.in_fast_event()
                        and vim.schedule_wrap(vim.api.nvim_buf_call)
                    or vim.api.nvim_buf_call

                -- update lir buffer to show updated git status
                buf_call(bufnr, function()
                    vim.cmd(":edit")
                end)

                print((stage and "Stage path: " or "Unstage path: ") .. short_path)
            end)
        end
        local stage_path = function()
            git_stage_unstage(true)
        end
        local unstage_path = function()
            git_stage_unstage(false)
        end

        ---@diagnostic disable-next-line: missing-fields
        lir.setup({
            show_hidden_files = true,
            ignore = {},
            devicons = {
                enable = true,
                highlight_dirname = false,
            },
            mappings = {
                ["<CR>"] = actions.edit,
                ["-"] = actions.up,

                ["d"] = actions.mkdir,
                ["%"] = actions.newfile,
                ["R"] = actions.rename,
                ["Y"] = actions.yank_path,
                ["D"] = actions.delete,
                ["yy"] = yank_rel_filename,

                -- disable horizontal line movements
                ["h"] = noop,
                ["l"] = noop,
                ["w"] = noop,
                ["b"] = noop,
                ["e"] = noop,
                ["0"] = noop,
                ["^"] = noop,
                ["$"] = noop,
                ["t"] = noop,
                ["f"] = noop,

                -- stage path under cursor
                ["<leader>hs"] = stage_path,
                -- unstage path under cursor
                -- TODO: toggle feature, <leader>hr does NOT actually correspond with the funtion
                --   of the equivalent hunk stage binding, as that binding restores the hunk!
                ["<leader>hr"] = unstage_path,
            },
            hide_cursor = true,
        })

        vim.keymap.set("n", "<leader>pv", function()
            local ft = vim.bo.filetype
            if ft == "lir" or ft == "fugitive" then
                return
            end

            -- update tag stack with departing item
            local from = { vim.fn.bufnr("%"), vim.fn.line("."), vim.fn.col("."), 0 }
            local items = { { tagname = vim.fn.expand("<cword>"), from = from } }
            vim.fn.settagstack(vim.fn.win_getid(), { items = items }, "t")

            vim.cmd.edit("%:h")
        end, {
            noremap = true,
            silent = true,
            desc = "O[p]en File Explorer [V]iew",
        })

        require("lir.git_status").setup({
            show_ignored = false,
        })
    end,
}

conf["init"] = function()
    local group_id = vim.api.nvim_create_augroup("LoadFileExplorer", { clear = false })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = group_id,
        once = false, -- must run until/unless a directory is viewed, will remove itself after
        callback = function(ev)
            local res = (vim.uv or vim.loop).fs_stat(vim.api.nvim_buf_get_name(ev.buf))
            if res and res.type == "directory" then
                local plugin_name = conf.name
                local slash = conf[1]:find("/", 1, true)
                if slash then
                    plugin_name = conf.name or conf[1]:sub(slash + 1)
                end
                require("lazy").load({ plugins = { plugin_name }, wait = true })
                vim.api.nvim_buf_call(ev.buf, function()
                    require("lir").init()
                end)

                vim.api.nvim_del_autocmd(ev.id)
                vim.api.nvim_del_augroup_by_id(ev.group)
            end
        end,
    })
end

return {
    conf,
    { "nvim-lua/plenary.nvim" },
    { "nvim-tree/nvim-web-devicons" },
}
