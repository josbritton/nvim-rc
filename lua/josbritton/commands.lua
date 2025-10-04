vim.api.nvim_create_user_command("CargoNew", function(args)
    local s = (vim.trim(args.args:lower())):gsub(" ", "-")
    local f = function()
        local cargo_manifest = [[
[features]

[package]
name = "%s"
version = "0.0.0"
publish = false
edition.workspace = true

[lints]
workspace = true

[lib]
path = "src/%s.rs"

[dependencies]
]]
        vim.fn.writefile(
            vim.split(cargo_manifest:format(s, s), "\n", { plain = true }),
            ("./crates/%s/Cargo.toml"):format(s),
            "s" -- fsync
        )

        vim.cmd.edit(("./crates/%s/src/%s.rs"):format(s, s))
    end
    ---@param next function
    ---@return fun(err: string?, success: boolean?)
    local cb = function(next)
        return function(err, ok)
            if not ok or err then
                print(err)
                return
            end
            next()
        end
    end
    local fn = function()
        vim.uv.fs_mkdir(
            ("./crates/%s/src"):format(s),
            tonumber("755", 8),
            vim.schedule_wrap(cb(f))
        )
    end

    vim.uv.fs_mkdir("./crates/" .. s, tonumber("755", 8), vim.schedule_wrap(cb(fn)))
end, { desc = "Create new cargo workspace member", nargs = "+" })
