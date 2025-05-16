local M = {}

---@param k string
---@param res vim.SystemCompleted
---@return string
local function get_version(k, res)
    if k == "shellcheck" then
        return res.stdout:match("version:%s+(%S+)")
    elseif k == "markdownlint" then
        return res.stdout:sub(1, res.stdout:len() - 1)
    end

    return (res.stdout or res.stderr):sub(
        k:len() + 2,
        (((res.stdout or res.stderr) .. "\n"):find("\n") - 1)
            or (res.stdout or res.stderr):len()
    )
end

---@param bins table<string, string[]>
---@param level vim.log.levels
local function check_bins(bins, level)
    Err = vim.log.levels.ERROR
    Warn = vim.log.levels.WARN

    if level > Err then
        level = Err
    elseif level < Warn then
        level = Warn
    end

    for name, args in pairs(bins) do
        if vim.fn.executable(args[1]) == 1 then
            -- health checks must be sync
            local res = vim.system(args, { text = true }):wait(10000)
            if res.code ~= 0 then
                local s = ("%s `%s`"):format(
                    name,
                    res.stderr:sub(1, (res.stderr .. "\n"):find("\n") - 1)
                )
                if level < Err then
                    vim.health.warn(s)
                else
                    vim.health.error(s)
                end
                goto continue
            end

            ---@type string
            local lhs = args[1]
            if args[1] == "rg" then
                lhs = "ripgrep"
            elseif args[1] == "make" and res.stdout:sub(1, 8) == "GNU Make" then
                lhs = "GNU Make"
            end

            vim.health.ok(("%s `%s`"):format(name, get_version(lhs, res)))
        else
            local s = ("%s not found"):format(args[1])
            if level < Err then
                vim.health.warn(s)
            else
                vim.health.error(s)
            end
        end
        ::continue::
    end
end

M.check_build_fzf_native = function()
    vim.health.start("fzf-native: build")

    local gcc = vim.fn.executable("gcc") == 1
    local clang = vim.fn.executable("clang") == 1
    if gcc or clang then
        if gcc then
            check_bins({
                ["gcc"] = { "gcc", "--version" },
            }, vim.log.levels.ERROR)
            return
        end
        if clang then
            check_bins({
                ["clang"] = { "clang", "--version" },
            }, vim.log.levels.ERROR)
            return
        end
    else
        vim.health.error("gcc OR clang not found")
    end

    check_bins({ ["GNU Make"] = { "make", "-v" } }, vim.log.levels.ERROR)
end

M.check_build_blink_cmp = function()
    vim.health.start("blink.cmp: build")

    if vim.fn.executable("rustup") ~= 1 and vim.fn.executable("cargo") ~= 1 then
        vim.health.error("Cargo not found", "Cannot build completion plug-in!")
        return
    end
    check_bins({
        ["cargo (nightly)"] = { "cargo", "+nightly", "-V" },
    }, vim.log.levels.ERROR)
end

M.check = function()
    M.check_build_blink_cmp()
    M.check_build_fzf_native()

    vim.health.start("Formatters")
    check_bins({
        ["stylua"] = { "stylua", "-V" },
        ["markdownlint"] = { "markdownlint", "-V" },
    }, vim.log.levels.ERROR)

    vim.health.start("Linters")
    check_bins({
        ["shellcheck"] = { "shellcheck", "-V" },
        ["markdownlint"] = { "markdownlint", "-V" },
        ["yamllint"] = { "yamllint", "--version" },
    }, vim.log.levels.ERROR)

    vim.health.start("LSP servers")
    check_bins({
        ["rust-analyzer"] = { "rust-analyzer", "-V" }, -- LSP
    }, vim.log.levels.WARN)

    vim.health.start("Telescope")
    check_bins({
        ["ripgrep"] = { "rg", "-V" }, -- required for live-grepping
        ["fd"] = { "fd", "-V" }, -- required for finding
    }, vim.log.levels.WARN)

    vim.health.start("Rust")
    check_bins({
        ["cargo"] = { "cargo", "-V" },
        ["cargo (nightly)"] = { "cargo", "+nightly", "-V" },
        ["rustc"] = { "rustc", "-V" },
        ["rustc (nightly)"] = { "rustc", "+nightly", "-V" },
        ["rust-analyzer"] = { "rust-analyzer", "-V" },
        ["rust-analyzer (nightly)"] = { "rust-analyzer", "+nightly", "-V" },
        ["rustup"] = { "rustup", "-V" },
    }, vim.log.levels.WARN)
end
return M
