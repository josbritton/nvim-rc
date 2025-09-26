local buf = vim.api.nvim_get_current_buf()

if vim.endswith(vim.fn.bufname(buf), "Cargo.toml") then
    vim.api.nvim_buf_create_user_command(buf, "CargoHover", function(args)
        local buf_pos = vim.api.nvim_win_get_cursor(0)
        local cword = vim.fn.expand("<cword>")
        local _proc = vim.system({
            "cargo",
            "info",
            "--color",
            "always",
            "--frozen",
            args.args,
        }, { timeout = 5000 }, function(res)
            local buf_call = vim.schedule_wrap(vim.api.nvim_buf_call)
            buf_call(buf, function()
                if res.code ~= 0 then
                    return
                end

                local hl_ns = vim.api.nvim_create_namespace("cargohover")
                if cword ~= "" then
                    local line =
                        vim.api.nvim_buf_get_lines(buf, buf_pos[1] - 1, buf_pos[1], false)
                    local offset = vim.fn.match(line, cword)
                    vim.hl.range(
                        buf,
                        hl_ns,
                        "LspReferenceText",
                        { buf_pos[1] - 1, offset },
                        { buf_pos[1] - 1, string.len(cword) },
                        { inclusive = false, timeout = -1 }
                    )
                end

                local buf = vim.api.nvim_create_buf(false, true)
                local win = vim.api.nvim_open_win(
                    buf,
                    true,
                    ---@type vim.api.keyset.win_config
                    {
                        relative = "win",
                        bufpos = buf_pos,
                        width = 125,
                        height = 14,
                        border = "single",
                    }
                )
                -- send AFTER window is once
                vim.api.nvim_chan_send(vim.api.nvim_open_term(buf, {}), res.stdout)

                vim.api.nvim_create_autocmd({
                    "BufLeave",
                    "CursorMoved",
                    "InsertEnter",
                }, {
                    once = true,
                    -- group = "",
                    callback = function(ev)
                        vim.api.nvim_buf_call(ev.buf, function()
                            vim.api.nvim_win_close(win, false)
                            vim.api.nvim_buf_clear_namespace(
                                ev.buf,
                                hl_ns,
                                buf_pos[1] - 1,
                                buf_pos[1]
                            )
                        end)
                        vim.api.nvim_del_autocmd(ev.id)
                    end,
                })
            end)
        end)
    end, { desc = "hello", nargs = "+", complete = "command" })
    vim.opt_local.keywordprg = ":CargoHover"
end

-- Add chars that are often part of keys, especially in rust crates
-- (https://toml.io/en/v1.0.0#keys)
vim.opt_local.iskeyword:append("-")
