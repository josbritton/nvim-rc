-- setup detection and action for large files
local id = vim.api.nvim_create_augroup("BigFilePreload", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPre" }, {
    group = id,
    once = true,
    callback = function(_ev)
        -- detect very large files and assign a unique filetype
        vim.filetype.add({
            pattern = {
                [".*"] = {
                    function(path, buf)
                        if not path or not buf or vim.bo[buf].filetype == "bigfile" then
                            return
                        end
                        if path ~= vim.api.nvim_buf_get_name(buf) then
                            return
                        end
                        local size = vim.fn.getfsize(path)
                        if size <= 0 then
                            return
                        end

                        local bigfile_size = 1.5 * 1024 * 1024 -- 1.5MB
                        if size > bigfile_size then
                            return "bigfile"
                        end
                        -- average line length (useful for minified files)
                        local bigfile_line_length = vim.o.synmaxcol or 400
                        local lines = vim.api.nvim_buf_line_count(buf)
                        return (size - lines) / lines > bigfile_line_length and "bigfile"
                            or nil
                    end,
                },
            },
        })

        local id = vim.api.nvim_create_augroup("BigFile", { clear = true })
        vim.api.nvim_create_autocmd({ "FileType" }, {
            group = id,
            pattern = "bigfile",
            callback = function(ev)
                local path =
                    vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":p:~:.")

                local s = ("Big file detected `%s`.\nSome Neovim features \z
                    have been **disabled**."):format(path)
                Notify.warn(s, { title = "Big File" })

                vim.api.nvim_buf_call(ev.buf, function()
                    -- disable auto-parenthesis match plugin
                    if vim.fn.exists(":NoMatchParen") ~= 0 then
                        vim.cmd([[NoMatchParen]])
                    end

                    vim.wo[0].foldmethod = "manual"
                    vim.wo[0].statuscolumn = ""
                    vim.wo[0].conceallevel = 0

                    -- enable normal syntax
                    local ft = vim.filetype.match({ buf = ev.buf }) or ""
                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(ev.buf) then
                            vim.bo[ev.buf].syntax = ft
                        end
                    end)
                end)
            end,
        })
    end,
})

-- show file immediately before loading plugins
local id = vim.api.nvim_create_augroup("QuickFile", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = id,
    once = true,
    callback = function(ev)
        if vim.v.vim_did_enter == 1 then
            return
        end

        -- try to guess the filetype (may change later on during startup)
        local ft = vim.filetype.match({ buf = ev.buf })
        if not ft then
            return
        end

        -- temporarily prevent normal redrawing as we will force a redraw later
        vim.opt.lazyredraw = true

        -- Add treesitter highlights and fallback to syntax
        local lang = vim.treesitter.language.get_lang(ft)

        -- disable treesitter for some langs
        if lang == "latex" then
            lang = nil
        end

        if not (lang and pcall(vim.treesitter.start, ev.buf, lang)) then
            vim.bo[ev.buf].syntax = ft
        end

        -- trigger early redraw
        vim.cmd([[redraw]])
        vim.opt.lazyredraw = false
    end,
})

-- lazily load core plugins on startup after init
local id = vim.api.nvim_create_augroup("LazyLoadAll", { clear = true })
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    group = id,
    once = true,
    callback = function(_ev)
        vim.schedule(function()
            require("lazy").load({
                plugins = {
                    "nvim-treesitter",
                    "nvim-lspconfig",
                    "blink.cmp",
                    "nvim-dap",
                    "lir-git-status.nvim",
                    "telescope.nvim",
                    "indent-blankline.nvim",
                    "Comment.nvim",
                    "nvim-colorizer.lua",
                    "spaceless.nvim",
                    "gitsigns.nvim",
                    "blink.pairs",
                    "nvim-lint",
                    "vim-rhubarb",
                    "conform.nvim",
                    "cloak.nvim",
                },
            })
        end)
    end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
    callback = function()
        Notify.warn(
            "File changed on disk. Buffer reloaded.",
            { title = "Buffer Reloaded" }
        )
    end,
})
