--- @class Statusline
local M = {}

--- @class (exact) Statusline.StatusObj
--- @field added? integer
--- @field removed? integer
--- @field changed? integer
--- @field head? string
--- @field root? string
--- @field gitdir? string

vim.opt.laststatus = 3

--- @param name string
--- @return table<string,any>
local function get_hl(name)
    return vim.api.nvim_get_hl(0, { name = name })
end

--- @param num integer
--- @param active 0|1
--- @return string
local function highlight(num, active)
    if active == 1 then
        if num == 1 then
            return "%#PmenuSel#"
        end
        return "%#StatusLine#"
    end
    return "%#StatusLineNC#"
end

local DIAG_ATTRS = {
    { "Error", "󰅚", "DiagnosticErrorStatus" },
    { "Warn", "󰀪", "DiagnosticWarnStatus" },
    { "Info", "󰋽", "DiagnosticInfoStatus" },
    { "Hint", "󰌶", "DiagnosticHintStatus" },
}
local GITSIGN_ATTRS = {
    { "Add", "+", "GitSignsAddStatus", "added" },
    { "Change", "~", "GitSignsChangeStatus", "changed" },
    { "Delete", "-", "GitSignsDeleteStatus", "deleted" },
}

local function hldefs()
    --- @type table<string,any>
    local statusline = get_hl("StatusLine")
    for _, attrs in ipairs(DIAG_ATTRS) do
        local fg = get_hl("Diagnostic" .. attrs[1]).fg
        vim.api.nvim_set_hl(0, attrs[3], { fg = fg, bg = statusline.bg })
    end

    for _, attrs in ipairs(GITSIGN_ATTRS) do
        local fg = get_hl("GitSigns" .. attrs[1]).fg
        vim.api.nvim_set_hl(0, attrs[3], { fg = fg, bg = statusline.bg })
    end

    vim.api.nvim_set_hl(0, "LspName", { fg = get_hl("Debug").fg, bg = statusline.bg })
    vim.api.nvim_set_hl(0, "StatusTS", statusline)
end

--- @param name string
--- @param active 0|1
--- @return string
local function hl(name, active)
    if active == 0 then
        return ""
    end
    return "%#" .. name .. "#"
end

--- @param active 0|1
--- @return string
local function lsp_name(active)
    local names = {} ---@type string[]
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        names[#names + 1] = client.name
    end

    if #names == 0 then
        return ""
    end

    return hl("LspName", active) .. table.concat(names, ",")
end

--- @param active 0|1
--- @return string
function M.linter_status(active)
    ---@type string
    local ft = vim.bo.filetype

    ---@type string[]
    local names = {}
    names = require("lint").linters_by_ft[ft]
    if names == nil or #names < 1 then
        return ""
    end

    return hl("LinterName", active) .. table.concat(names, ", ")
end

--- @param active 0|1
--- @return string?
local function diagnostics(active)
    local status = {} ---@type string[]
    local diags = vim.diagnostic.count(0)
    for i, attrs in ipairs(DIAG_ATTRS) do
        ---@type integer
        local n = diags[i] or 0
        if n > 0 then
            table.insert(status, (" %s%s %d"):format(hl(attrs[3], active), attrs[2], n))
        end
    end

    if #status == 0 then
        return
    end

    return table.concat(status, " ")
end

--- @param active 0|1
--- @return string
function M.lsp_status(active)
    local status = {} ---@type string[]

    status[#status + 1] = lsp_name(active)
    status[#status + 1] = diagnostics(active)

    if vim.g.metals_status then
        status[#status + 1] = vim.g.metals_status:gsub("%%", "%%%%")
    end

    return table.concat(status, " ")
end

---@type boolean
local gitsigns_color_enabled = false

---@param status Statusline.StatusObj
---@param active 0|1
---@return string
local gitsigns_formatter = function(status, active)
    ---@type string[]
    local segments = {}
    ---@type string?
    local head = status.head

    for _, attrs in ipairs(GITSIGN_ATTRS) do
        ---@type integer?
        local field = status[attrs[4]]
        if field and field > 0 then
            local prefix = attrs[2]
            if gitsigns_color_enabled then
                prefix = hl(attrs[3], active) .. prefix
            end
            table.insert(segments, prefix .. field)
        end
    end

    if #segments == 0 then
        if head and head ~= "" then
            return head
        end
        return ""
    end

    if head and head ~= "" then
        table.insert(segments, 1, head)
    end

    return table.concat(segments, " ")
end

---@param active 0|1
---@return string
function M.hunks(active)
    ---@type Statusline.StatusObj
    local gs_status_dict = vim.b.gitsigns_status_dict
    if gs_status_dict then
        local status = vim.b.gitsigns_head ---@type string?
        local result = gitsigns_formatter(gs_status_dict, active) ---@type string

        if result ~= "" then
            status = result
        end
        return status or ""
    end

    return vim.g.gitsigns_head or ""
end

--- @param active 0|1
--- @return string
local function filetype_symbol(active)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
        return ""
    end

    ---@type string
    local name = vim.api.nvim_buf_get_name(0)
    ---@type string, string
    local icon, iconhl =
        devicons.get_icon_color(name, vim.bo.filetype, { default = true })

    ---@type string
    local hlname = iconhl:gsub("#", "Status")
    vim.api.nvim_set_hl(0, hlname, { fg = iconhl, bg = get_hl("StatusLine").bg })

    return hl(hlname, active) .. icon
end

---@return boolean
local function is_treesitter()
    ---@type integer
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr] ~= nil
end

--- @param active 0|1
--- @return string
function M.filetype(active)
    ---@type string[]
    local r = {
        vim.bo.filetype,
        filetype_symbol(active),
    }

    if is_treesitter() then
        r[#r + 1] = hl("StatusTS", active) .. "ts"
    end

    return table.concat(r, " ")
end

---@return string
function M.encodingAndFormat()
    local e = vim.bo.fileencoding and vim.bo.fileencoding or vim.o.encoding ---@type string

    local r = {} ---@type string[]
    if e ~= "utf-8" then
        r[#r + 1] = e
    end

    local f = vim.bo.fileformat ---@type string
    if f ~= "unix" then
        r[#r + 1] = "[" .. f .. "]"
    end

    return table.concat(r, " ")
end

--- @return string
function M.bufname()
    local buf_name = vim.api.nvim_buf_get_name(0) ---@type string
    if vim.startswith(buf_name, "fugitive://") then
        local _, _, revision, relpath =
            buf_name:find([[^fugitive://.*/%.git.*/(%x-)/(.*)]])
        return relpath .. "@" .. revision:sub(1, 7)
    elseif vim.startswith(buf_name, "gitsigns://") then
        local _, _, revision, relpath =
            buf_name:find([[^gitsigns://.*/%.git.*/(.*):(.*)]])
        return relpath .. "@" .. revision:sub(1, 7)
    end

    local full_path = vim.fn.expand("%:p") ---@type string
    local cwd = vim.loop.cwd() or vim.loop.fs_realpath(".") or "" ---@type string

    if full_path == cwd then
        return ""
    end

    -- append terminating slash to cwd
    if string.sub(cwd, -1) ~= "/" then
        cwd = cwd .. "/"
    end

    -- return relative difference
    if full_path:sub(1, #cwd) == cwd then
        return full_path:sub(#cwd + 1, -1)
    end

    local home = vim.loop.os_homedir() or "" ---@type string

    -- append terminating slash to home dir
    if string.sub(home, -1) ~= "/" then
        home = home .. "/"
    end

    -- if relative to home dir, return difference
    local start, finish = string.find(full_path, home, 1, true) ---@type integer?, integer?
    if start == 1 then
        return "~" .. "/" .. string.sub(full_path, (finish + 1), -1)
    end

    return full_path
end

--- @param x string
--- @return string
local function pad(x)
    return "%( " .. x .. " %)"
end

--- @type Statusline
local F = setmetatable({}, {
    ---@param t table
    ---@param name string
    ---@return string
    __index = function(t, name)
        ---@param active 1|0?
        ---@param mods string?
        ---@return string
        t[name] = function(active, mods) ---@type function
            active = active or 1
            mods = mods or ""
            return "%"
                .. mods
                .. "{%v:lua.statusline."
                .. name
                .. "("
                .. tostring(active)
                .. ")%}"
        end
        return t[name]
    end,
})

--- @param sections string[][]
--- @return string
local function parse_sections(sections)
    local result = {} ---@type string[]
    for _, s in ipairs(sections) do
        local sub_result = {} ---@type string[]
        for _, part in ipairs(s) do
            sub_result[#sub_result + 1] = part
        end
        result[#result + 1] = table.concat(sub_result)
    end
    return table.concat(result, "%=")
end

--- @param active 0|1
--- @param global? boolean
local function set(active, global)
    ---@type string
    local scope = global and "o" or "wo"
    ---@type string
    vim[scope].statusline = parse_sections({
        {
            highlight(1, active),
            pad(F.hunks(active)),
            highlight(2, active),
            pad(F.lsp_status(active)),
            highlight(2, active),
            pad(F.linter_status(active)),
            highlight(2, active),
            "%<",
            pad(F.bufname() .. "%m%r%h%q"),
        },
        {
            pad(F.filetype(active)),
            pad(F.encodingAndFormat()),
            highlight(1, active),
            " %3l,%-3v  %3P ",
        },
    })
end

---@type integer
local group = vim.api.nvim_create_augroup("statusline", { clear = true })

-- only set up WinEnter autocmd when the WinLeave autocmd runs
vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
    group = group,
    once = true,
    callback = function()
        vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FocusGained" }, {
            group = group,
            callback = function()
                set(1)
            end,
        })
    end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
    group = group,
    callback = function()
        set(0)
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        set(1, true)
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = hldefs,
})

hldefs()

---@type function
local redrawstatus = vim.schedule_wrap(function()
    vim.api.nvim__redraw({ statusline = true })
end)

-- delay creating frequently updating autocmds until first file read
vim.api.nvim_create_autocmd({
    "BufNewFile",
    "BufReadPost",
    "FilterReadPost",
    "FileReadPost",
}, {
    group = group,
    once = true,
    callback = function()
        vim.api.nvim_create_autocmd("User", {
            pattern = "GitSignsUpdate",
            group = group,
            callback = redrawstatus,
        })
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            group = group,
            callback = redrawstatus,
        })
    end,
})

_G.statusline = M

return M
