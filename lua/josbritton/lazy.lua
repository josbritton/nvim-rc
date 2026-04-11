local lazypath = vim.fn.stdpath("state") .. "/lazydata/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(PLUGINS, {
    root = vim.fn.stdpath("state") .. "/lazydata",
    install = { missing = true },
    checker = {
        -- disable automatic network activity
        enabled = false,
        notify = false,
        concurrency = math.ceil(vim.uv.available_parallelism() / 2),
    },
    dev = {
        ---@type string | fun(plugin: LazyPlugin): string
        path = "~/Sync",
        fallback = true,
    },
    change_detection = { notify = false },
    rocks = { enabled = false },
    concurrency = math.ceil(vim.uv.available_parallelism() / 2),
})
