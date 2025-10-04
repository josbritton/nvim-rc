---@type conform.setupOpts
local opts = {
    notify_on_error = false,
    formatters_by_ft = {
        lua = { "stylua" },
        markdown = { "markdownlint" },
    },
}

---@type LazyPluginSpec
return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    init = function()
        local gid = vim.api.nvim_create_augroup("AutoFormatGroup", { clear = true })
        for ft, _ in pairs(opts["formatters_by_ft"] or {}) do
            vim.api.nvim_create_autocmd({ "FileType" }, {
                pattern = ft,
                group = gid,
                callback = function(ev)
                    ---@type function
                    local enable_autoformatting
                    ---@type function
                    local create_autoformat_off_cmd
                    ---@type function
                    local create_autoformat_on_cmd

                    -- create a command `:Format` local to the buffer
                    vim.api.nvim_buf_create_user_command(ev.buf, "Format", function(_)
                        vim.schedule(function()
                            require("conform").format({
                                bufnr = ev.buf,
                                async = true,
                                lsp_format = "never", -- handle lsp autoformatting ourselves
                            })
                        end)
                    end, { desc = "Format current buffer" })

                    ---@return number # The ID number of the autocommand that was just created
                    enable_autoformatting = function()
                        return vim.api.nvim_create_autocmd("BufWritePre", {
                            group = gid,
                            buffer = ev.buf,
                            callback = function(ev)
                                require("conform").format({
                                    bufnr = ev.buf,
                                    async = false,
                                    lsp_format = "never", -- handle lsp autoformatting ourselves
                                })
                            end,
                        })
                    end

                    ---@param cmd number The ID number of the autocommand to be deleted
                    ---@return nil
                    create_autoformat_off_cmd = function(cmd)
                        pcall(vim.api.nvim_buf_del_user_command, ev.buf, "AutoFormatON")

                        -- use with `:AutoFormatOFF`, buffer-local & temporary
                        vim.api.nvim_buf_create_user_command(
                            ev.buf,
                            "AutoFormatOFF",
                            function()
                                local ok, _ = pcall(vim.api.nvim_del_autocmd, cmd)
                                if ok then
                                    create_autoformat_on_cmd()
                                end
                            end,
                            { desc = "Disable automatic formatting before saving" }
                        )
                    end

                    ---@return nil
                    create_autoformat_on_cmd = function()
                        pcall(vim.api.nvim_buf_del_user_command, ev.buf, "AutoFormatOFF")

                        -- use with `:AutoFormatON`, buffer-local & temporary
                        vim.api.nvim_buf_create_user_command(
                            ev.buf,
                            "AutoFormatON",
                            function()
                                local ok, cmd = pcall(enable_autoformatting)
                                if ok then
                                    create_autoformat_off_cmd(cmd)
                                end
                            end,
                            { desc = "Enable automatic formatting before saving" }
                        )
                    end

                    local ok, cmd = pcall(enable_autoformatting)
                    if ok then
                        create_autoformat_off_cmd(cmd)
                    end
                end,
            })
        end
    end,
    opts = opts,
}
