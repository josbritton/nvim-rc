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

        local actions = require("lir.actions")
        local noop = function() end

        require("lir").setup({
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
                local lazy = require("lazy")

                local plugin_name = conf.name
                local slash = conf[1]:find("/", 1, true)
                if slash then
                    plugin_name = conf.name or conf[1]:sub(slash + 1)
                end
                lazy.load({ plugins = plugin_name })

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
