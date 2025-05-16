---@type LazyPluginSpec
return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio", -- dep for dap-ui
        "theHamsta/nvim-dap-virtual-text",
        "j-hui/fidget.nvim", -- used for build progress display TODO
    },
    keys = {
        { "<leader>b", nil, mode = "n", desc = "DAP: Toggle breakpoint" },
        { "<leader>?", nil, mode = "n", desc = "DAP: Evaluate variable under cursor" },
        { "<F1>", nil, mode = "n", desc = "DAP: Continue" },
        { "<F2>", nil, mode = "n", desc = "DAP: Step-into" },
        { "<F3>", nil, mode = "n", desc = "DAP: Step-over" },
        { "<F4>", nil, mode = "n", desc = "DAP: Step-out" },
        { "<F5>", nil, mode = "n", desc = "DAP: Step-back" },
    },
    lazy = true,
    config = function()
        local rust_build_timeout_ms = 20 * 60 * 1000 -- 20 minutes

        ---@return string? bin_path Returns path to binary if build was successful
        ---@param args string[]?
        local function cargo_build(args)
            local cargo = vim.fn.exepath("cargo")
            if cargo == "" then
                Notify.error("`cargo` not found in path.", { title = "Cargo build" })
                return
            end

            local build_cmd = vim.tbl_extend("keep", {
                "cargo",
                "build",
                "--profile=dev",
                "--message-format=json-render-diagnostics",
            }, args or {})

            local build = vim.system(build_cmd):wait(rust_build_timeout_ms)

            if build.code ~= 0 then
                Notify.error(("Build failed:\n\n%s"):format(build.stderr or "No stderr!"))
                return
            end

            if build.stderr and build.stderr ~= "" then
                Notify.warn(build.stderr, { title = "Cargo build output" })
            end

            local manifest = vim.fn.getcwd() .. "/Cargo.toml"
            for s in vim.gsplit(build.stdout, "\n") do -- artifacts delimited with newline chars
                local json = vim.json.decode(s) or {}
                if
                    json["reason"] == "compiler-artifact"
                    and json["manifest_path"] == manifest
                then
                    for _i, kind in ipairs(json["target"]["kind"] or {}) do
                        if kind == "bin" and json["executable"] then
                            -- return first binary executable artifact emitted from `cargo build`
                            -- with same `Cargo.toml` location as the current project
                            return json["executable"]
                        end
                    end
                end
            end
        end

        local dap = require("dap")
        local ui = require("dapui")

        require("dapui").setup({
            mappings = {
                edit = { "E" },
            },
        })
        require("nvim-dap-virtual-text").setup()

        local rust_gdb = vim.fn.exepath("rust-gdb")
        if rust_gdb ~= "" then
            dap.adapters.rust_gdb = {
                type = "executable",
                command = "rust-gdb",
                args = { "-q", "--interpreter=dap" },
            }
            dap.adapters.cppdbg = {
                id = "cppdbg",
                type = "executable",
                command = "cppdbg",
            }
            dap.configurations.rust = {
                {
                    name = "Launch",
                    -- type = "cppdbg",
                    type = "rust_gdb",
                    request = "launch",
                    program = function()
                        return cargo_build() -- build default target
                            or function() -- otherwise, prompt for target name
                                local target = vim.fn.input("Target name: ")
                                return cargo_build({ "--target=" .. target })
                            end
                    end,
                    cwd = "${workspaceFolder}",
                    -- MIMode = "gdb",
                    -- miDebuggerPath = "/usr/bin/rust-gdb",
                    stopAtEntry = true,
                    stopAtBeginningOfMainSubprogram = false,
                    showDisassembly = "never",
                },
            }
        end

        vim.keymap.set(
            "n",
            "<leader>b",
            dap.toggle_breakpoint,
            { desc = "DAP: Toggle breakpoint" }
        )
        -- vim.keymap.set(
        --     "n",
        --     "<leader>b",
        --     dap.run_to_cursor,
        --     { desc = "DAP: Run to cursor" }
        -- )

        vim.keymap.set("n", "<leader>?", function()
            require("dapui").eval(nil, { enter = true })
        end, { desc = "DAP: Evaluate variable under cursor" })

        vim.keymap.set("n", "<F1>", dap.continue, { desc = "DAP: Continue" })
        vim.keymap.set("n", "<F2>", dap.step_into, { desc = "DAP: Step-into" })
        vim.keymap.set("n", "<F3>", dap.step_over, { desc = "DAP: Step-over" })
        vim.keymap.set("n", "<F4>", dap.step_out, { desc = "DAP: Step-out" })
        vim.keymap.set("n", "<F5>", dap.step_back, { desc = "DAP: Step-back" })
        -- vim.keymap.set("n", "<F13>", dap.restart, { desc = "DAP: Restart" })

        dap.listeners.before.attach.dapui_config = function()
            ui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            ui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            ui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            ui.close()
        end
    end,
}
