vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })
vim.keymap.set(
    "n",
    "<leader>e",
    vim.diagnostic.open_float,
    { desc = "Open floating diagnostic message" }
)

vim.keymap.set(
    { "c", "i" },
    "<C-BS>",
    "<C-S-W>",
    { noremap = true, desc = "Delete word" }
)
vim.keymap.set({ "c", "i" }, "<C-h>", "<C-S-W>", { noremap = true, desc = "Delete word" })

vim.keymap.set(
    "n",
    "<Esc>",
    "<Cmd>noh<CR>",
    { noremap = true, desc = "Clear highlighting" }
)

-- center buffer on search result navigation
vim.keymap.set("n", "n", "nzzzv", { noremap = true })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true })

vim.keymap.set("n", "*", "*zz", { noremap = true })
vim.keymap.set("n", "#", "#zz", { noremap = true })
vim.keymap.set("n", "g*", "g*zz", { noremap = true })
vim.keymap.set("n", "g#", "g#zz", { noremap = true })

-- center cursor on first result from scroll
vim.keymap.set("c", "<CR>", function()
    return string.find(vim.fn.getcmdtype(), "[/?]") and "<CR>zz" or "<CR>"
end, { expr = true, noremap = true })

-- center buffer on `ctrl + d/u`
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true })

-- keep cursor in place with `J`
vim.keymap.set("n", "J", "mzJ`z")

-- move lines
vim.keymap.set(
    "n",
    "<A-j>",
    "<Cmd>m .+1<CR>==",
    { noremap = true, desc = "Move line down" }
)
vim.keymap.set(
    "n",
    "<A-k>",
    "<Cmd>m .-2<CR>==",
    { noremap = true, desc = "Move line up" }
)
vim.keymap.set(
    "i",
    "<A-j>",
    "<Esc><Cmd>m .+1<CR>==gi",
    { noremap = true, desc = "Move line down" }
)
vim.keymap.set(
    "i",
    "<A-k>",
    "<Esc><Cmd>m .-2<CR>==gi",
    { noremap = true, desc = "Move line up" }
)
vim.keymap.set(
    "v",
    "<A-j>",
    "<Cmd>m '>+1<CR>gv=gv",
    { noremap = true, desc = "Move line down" }
)
vim.keymap.set(
    "v",
    "<A-k>",
    "<Cmd>m '>-2<CR>gv=gv",
    { noremap = true, desc = "Move line up" }
)

vim.keymap.set("n", "Q", "<Nop>")

vim.keymap.set("n", "<C-f>", "<Cmd>silent !tmux neww switchproj<CR>")
vim.keymap.set("n", "<C-j>", "<Cmd>silent !tmux neww tmuxopensesh<CR>")
vim.keymap.set("n", "<C-Space>", "<Cmd>silent !scratchtmux<CR>")

vim.keymap.set("n", "<leader>S", [[:%s/]], { desc = "Enter substitute command" })
vim.keymap.set("x", "<leader>S", [[:s/]], { desc = "Enter substitute command" })

vim.keymap.set(
    "n",
    "<leader>s",
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Find and replace the word under the cursor" }
)

local termcode = {
    left = vim.api.nvim_replace_termcodes("<Left>", true, false, true),
    esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
    c_r = vim.api.nvim_replace_termcodes("<C-r>", true, false, true),
}
vim.keymap.set("x", "<leader>s", function()
    -- must get current mode before potentially altering using ESC input later
    local mode = vim.fn.mode()

    -- must exit visual mode before continuing
    vim.api.nvim_feedkeys(termcode.esc, "nx", false)

    local marks = { "<", ">" }
    local sln, eln =
        vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])
    local region = { srow = sln[1], scol = sln[2], erow = eln[1], ecol = eln[2] }

    ---@type string[]
    local sel
    if mode == "V" then -- mode is visual-block
        if region.srow == region.erow then
            -- if visual-block and no range on row markers,
            -- then we must be selecting the current line only
            sel = { vim.api.nvim_get_current_line() }
        else
            sel = vim.api.nvim_buf_get_lines(0, region.srow - 1, region.erow, false)
        end
    else -- otherwise mode is visual
        sel = vim.api.nvim_buf_get_text(
            0,
            region.srow - 1,
            region.scol,
            region.erow - 1,
            region.ecol + 1,
            {}
        )
    end

    for i, v in ipairs(sel) do
        if mode == "V" then
            v = vim.trim(v)
        end
        v = v:gsub("\\", "\\\\")
        v = v:gsub("%/", "\\/")
        sel[i] = v
    end

    local subst = table.concat(sel, "\\n")
    subst = subst:gsub("%.", "\\.")
    subst = subst:gsub("%*", "\\*")
    subst = subst:gsub("%[", "\\[")
    subst = subst:gsub("%^", "\\^")
    subst = subst:gsub("%$", "\\$")

    local repl = table.concat(sel, "\\r")
    repl = repl:gsub("%&", "\\&")

    local text_len = subst:len() + repl:len()
    if text_len < 2 then
        -- empty substitution, do nothing
        return
    end

    local max_subst_len = 200
    if text_len > max_subst_len then
        local s = ("Substitution cancelled.\nMaximum combined substitution \z
            + replacement payload length\nis set to `%s`, while requested length \z
            is `%s`."):format(max_subst_len, text_len)
        Notify.warn(s, { title = "Substitution failed" })

        return
    end

    vim.fn.setreg("s", subst)
    vim.fn.setreg("r", repl)

    local subst_flags = "gI"

    -- calculate cursor movement using length of subst_flags
    local suff_v = { subst_flags }
    for i = 2, subst_flags:len() + 2 do
        table.insert(suff_v, i, termcode.left)
    end
    local suff = table.concat(suff_v, "")

    local s = (":%%s/%ss/%sr/%s"):format(termcode.c_r, termcode.c_r, suff)

    vim.api.nvim_feedkeys(s, "n", false)
end, { desc = "Find and replace the current selection" })

vim.keymap.set(
    "n",
    "<leader>x",
    "<cmd>!chmod +x %<CR>",
    { silent = true, desc = "Make the current file e[x]ecutable" }
)

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end, { desc = "Source current file" })

vim.keymap.set("n", "<leader>f", "<Cmd>Format<cr>", { desc = "Format current buffer" })
