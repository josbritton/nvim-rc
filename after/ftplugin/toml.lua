local buf = vim.api.nvim_get_current_buf()
local path = vim.fn.fnamemodify(vim.fn.bufname(buf), ":p:h")
local gid = vim.api.nvim_create_augroup("cargohoverclearpopup", { clear = false })

---@type table<string, table<string, string>>
local info_cache = {}

---@param cword string
---@param buf_pos integer[]
---@param s string
local function do_hover(cword, buf_pos, s)
    vim.api.nvim_exec_autocmds({
        "BufLeave",
        "CursorMoved",
        "InsertEnter",
    }, { group = gid })

    local hl_ns = vim.api.nvim_create_namespace("cargohover")
    if cword ~= "" then
        local line = vim.api.nvim_buf_get_lines(buf, buf_pos[1] - 1, buf_pos[1], false)
        local offset =
            vim.fn.match(line[1], cword, math.max(buf_pos[2] - string.len(cword), 0))
        vim.hl.range(
            buf,
            hl_ns,
            "LspReferenceText",
            { buf_pos[1] - 1, offset },
            { buf_pos[1] - 1, offset + string.len(cword) },
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
    vim.api.nvim_chan_send(vim.api.nvim_open_term(buf, {}), s)

    vim.api.nvim_create_autocmd({
        "BufLeave",
        "CursorMoved",
        "InsertEnter",
    }, {
        once = true,
        group = gid,
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
end

if vim.endswith(vim.fn.bufname(buf), "Cargo.toml") then
    vim.api.nvim_buf_create_user_command(buf, "CargoHover", function(args)
        local buf_call = vim.schedule_wrap(vim.api.nvim_buf_call)

        local buf_pos = vim.api.nvim_win_get_cursor(0)
        local cword = vim.fn.expand("<cword>")

        if info_cache[path] and info_cache[path][args.args] then
            buf_call(buf, function()
                do_hover(cword, buf_pos, info_cache[path][args.args])
            end)
            return
        end
        local _proc = vim.system({
            "cargo",
            "info",
            "--color",
            "always",
            "--frozen",
            args.args,
        }, { timeout = 5000 }, function(res)
            if res.code ~= 0 or not res.stdout then
                return
            end

            if not info_cache[path] then
                info_cache[path] = {}
            end
            info_cache[path][args.args] = res.stdout

            buf_call(buf, function()
                do_hover(cword, buf_pos, res.stdout)
            end)
        end)
    end, { nargs = "+", complete = "command" })
    vim.opt_local.keywordprg = ":CargoHover"
end

-- Add chars that are often part of keys, especially in rust crates
-- (https://toml.io/en/v1.0.0#keys)
vim.opt_local.iskeyword:append("-")
