local state = vim.fn.stdpath("state")
local data = vim.fn.stdpath("data")

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- time in ms before keymap sequence is completed
vim.opt.timeoutlen = 1000

-- override formatoptions for all buffers
local gid = vim.api.nvim_create_augroup("FormatOptionForcer", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
    group = gid,
    callback = function()
        -- do not automatically insert current comment leader after
        -- hitting 'o' or 'O' in normal mode
        vim.opt.formatoptions:remove("o")
    end,
})

-- ignore compiled files
---@diagnostic disable-next-line: param-type-mismatch
vim.opt.wildignore:append({
    "*.o",
    "*~",
    "*.pyc",
    "*pycache*",
    "Cargo.lock",
    "Cargo.Bazel.lock",
})

vim.opt.spelllang = "en_us"
vim.opt.spellfile = data .. "/en.utf-8.add"

-- show only commands and output in the command bar
vim.opt.showcmd = false
vim.opt.showmode = false

-- prefer splitting bottom, right
vim.opt.splitbelow = true
vim.opt.splitright = true

-- resize all vim windows after splitting or closing one
vim.opt.equalalways = true

-- auto-resize vim-windows equally when the parent window is resized
local gid = vim.api.nvim_create_augroup("AutoResize", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = gid,
    callback = function()
        -- only continue if there is more than one window open
        if vim.fn.winnr("$") > 1 then
            -- note that the command must be sent immediately to avoid hangs
            -- in other words: do not schedule this
            vim.cmd("wincmd =")
        end
    end,
})

-- *mostly* unload hidden buffers to minimize resource usage
vim.go.hidden = false

-- global statusline
vim.opt.laststatus = 3

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.o.cursorline = true
vim.o.cursorlineopt = "number"

vim.opt.mouse = "a"

-- use and sync nvim clipboard to OS clipboard
--  schedule the setting after `UiEnter` because it can increase startup-time
vim.schedule(function()
    vim.opt.clipboard = "unnamedplus"
end)

-- https://github.com/neovim/neovim/issues/23650
--vim.g.netrw_banner = 0

vim.opt.breakindent = true

-- permanently lost if file is modified externally!
vim.opt.undofile = true
vim.opt.undodir = state .. "/undo//" -- def

vim.opt.backup = true
vim.opt.backupdir = state .. "/backup//"

vim.opt.swapfile = true

-- case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.smartindent = true
vim.opt.expandtab = true

-- default for when sleuth has NO reference
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

---@diagnostic disable-next-line: param-type-mismatch
vim.opt.diffopt:append({
    "hiddenoff", -- no diff for hidden bufs
    "algorithm:minimal", -- spend extra cycles for the smallest possible diff
})

-- render space for column even if it has no content (prevents text from shifting)
vim.opt.signcolumn = "yes"

-- time in ms if nothing is typed to write to swap and trigger `CursorHold` autocmd event
-- (for example, showing completions on hover)
vim.opt.updatetime = 1000

---@diagnostic disable-next-line: missing-fields
vim.opt.completeopt = { "menuone", "noselect" }

vim.opt.termguicolors = true

vim.opt.wrap = false

-- vim.o.cursorline = true
---@diagnostic disable-next-line: missing-fields
vim.opt.backspace = { "indent", "eol", "start" }

vim.opt.scrolloff = 14

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.inccommand = "split"

vim.opt.list = true
---@diagnostic disable-next-line: missing-fields
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.autoread = true
-- no need to do syntax highlighting past this many cols
vim.opt.synmaxcol = 400

vim.opt.winborder = "single"

vim.filetype.add({
    extension = {
        mdx = "mdx",
        conf = "conf",
    },
    filename = {
        [".yamllint"] = "yaml",
        ["Chart.lock"] = "yaml",
    },
    pattern = {
        ["${HOME}/%.config/yamllint/config"] = "yaml",
        ["${XDG_CONFIG_HOME}/yamllint/config"] = "yaml",
        ["${HOME}/%.config/git/config"] = "gitconfig",
        ["${XDG_CONFIG_HOME}/git/config"] = "gitconfig",
    },
})

---@type vim.diagnostic.Opts
local diag = {
    virtual_text = nil,
    severity_sort = true, -- why is this not set by default?
    update_in_insert = true,
    underline = {
        severity = 4,
    },
}
vim.diagnostic.config(diag)

vim.keymap.set("n", "<leader>td", function()
    local opts = vim.diagnostic.config() or diag
    -- toggle severity filter to/from ERROR, HINT (all)
    opts.underline.severity = opts.underline.severity < 4 and 4 or 1
    vim.diagnostic.config(opts)
end, { desc = "[T]oggle [D]iagnostics" })

-- remove builtin
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1

vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1

-- vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1

vim.g.loaded_netrwFileHandlers = 1
