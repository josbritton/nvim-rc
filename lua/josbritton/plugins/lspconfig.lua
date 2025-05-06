-- Create a new buffer-local normal mode keymap
---@param keys string
---@param func function
---@param desc string
---@param buf integer
local nmap = function(keys, func, desc, buf)
    vim.keymap.set("n", keys, func, { buffer = buf, desc = "LSP: " .. desc })
end

---@type integer
local attach_gid = vim.api.nvim_create_augroup("lsp-attach", { clear = true })

-- Setup LSP handlers for server responses
---@param client vim.lsp.Client
---@return nil
local function setup_lsp_handlers(client)
    if
        client.name == "rust_analyzer"
        and not vim.lsp.handlers["experimental/serverStatus"]
    then
        -- Persistent server status notification for Rust Analyzer
        -- docs: https://rust-analyzer.github.io/book/contributing/lsp-extensions.html#server-status
        ---@class (exact) RAServerStatusParams
        --- `ok` means that the server is completely functional.
        ---
        --- `warning` means that the server is partially functional.
        --- It can answer correctly to most requests, but some results
        --- might be wrong due to, for example, some missing dependencies.
        ---
        --- `error` means that the server is not functional. For example,
        --- there's a fatal build configuration problem. The server might
        --- still give correct answers to simple requests, but most results
        --- will be incomplete or wrong.
        ---@field health "ok"|"warning"|"error"
        --- Is there any pending background work which might change the status?
        --- For example, are dependencies being downloaded?
        ---@field quiescent boolean
        --- Explanatory message to show on hover.
        ---@field message? string

        -- local gid =
        --     vim.api.nvim_create_augroup("RustAnalyzer", { clear = true })

        ---@class (exact) RAServerStatusHandler
        ---@param err lsp.ResponseError
        ---@param res RAServerStatusParams
        ---@param _ctx lsp.HandlerContext
        vim.lsp.handlers["experimental/serverStatus"] = function(err, res, _ctx)
            if err then
                Notify.error(
                    "LSP handler error: " .. err.message,
                    { title = "rust_analyzer: serverStatus handler" }
                )
                -- todo: try and handle this?
                return
            end

            vim.g.rust_analyzer_server_status = res.quiescent and res.health or "working"

            -- todo: send data?
            -- vim.api.nvim_exec_autocmds("User", {
            --     pattern = "RustAnalyzerStatusUpdate",
            --     group = gid,
            -- })
            vim.api.nvim__redraw({ statusline = true })
        end
    end

    -- other handlers
end

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "b0o/schemastore.nvim",
        { "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
        "williamboman/mason-lspconfig.nvim",
        { "j-hui/fidget.nvim", opts = {} }, -- status UI when loading LSP
    },
    event = { "BufReadPre", "BufNewFile" },
    init = function()
        vim.g.rust_analyzer_server_status = {}
    end,
    config = function()
        ---@type string[]
        local required_bins = {
            "rust-analyzer",
        }
        for _i, e in ipairs(required_bins) do
            assert(
                vim.fn.executable(e) == 1,
                ("`%s` not installed or available."):format(e)
            )
        end

        local util = require("lspconfig.util")
        vim.api.nvim_create_autocmd("LspAttach", {
            group = attach_gid,
            callback = function(ev)
                -- jump to the definition of the word under your cursor.
                --  This is where a variable was first declared, or where a function is defined, etc.
                --  To jump back, press <C-t>.
                nmap(
                    "gd",
                    require("telescope.builtin").lsp_definitions,
                    "[G]oto [D]efinition",
                    ev.buf
                )

                -- find references for the word under your cursor.
                nmap(
                    "gr",
                    require("telescope.builtin").lsp_references,
                    "[G]oto [R]eferences",
                    ev.buf
                )

                -- jump to the implementation of the word under your cursor.
                --  Useful when your language has ways of declaring types without an actual implementation.
                nmap(
                    "gI",
                    require("telescope.builtin").lsp_implementations,
                    "[G]oto [I]mplementation",
                    ev.buf
                )

                -- jump to the type of the word under your cursor.
                --  useful when you're not sure what type a variable is and you want to see
                --  the definition of its *type*, not where it was *defined*.
                nmap(
                    "<leader>D",
                    require("telescope.builtin").lsp_type_definitions,
                    "Type [D]efinition",
                    ev.buf
                )

                -- fuzzy find all the symbols in your current document.
                --  symbols are things like variables, functions, types, etc.
                nmap(
                    "<leader>ds",
                    require("telescope.builtin").lsp_document_symbols,
                    "[D]ocument [S]ymbols",
                    ev.buf
                )

                -- fuzzy find all the symbols in your current workspace.
                --  similar to document symbols, except searches over your entire project.
                nmap(
                    "<leader>ws",
                    require("telescope.builtin").lsp_dynamic_workspace_symbols,
                    "[W]orkspace [S]ymbols",
                    ev.buf
                )

                -- rename the variable under your cursor.
                --  most Language Servers support renaming across files, etc.
                nmap("<leader>rn", vim.lsp.buf.rename, "LSP: [R]e[n]ame Item", ev.buf)

                -- execute a code action, usually your cursor needs to be on top of an error
                -- or a suggestion from your LSP for this to activate.
                nmap(
                    "<leader>ca",
                    vim.lsp.buf.code_action,
                    "LSP: [C]ode [A]ction",
                    ev.buf
                )

                -- opens a popup that displays documentation about the word under your cursor
                --  see `:help K` for why this keymap.
                nmap("K", vim.lsp.buf.hover, "Hover Documentation", ev.buf)

                nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration", ev.buf)

                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if client == nil then
                    return
                end

                if
                    client.server_capabilities.inlayHintProvider
                    and vim.lsp.inlay_hint
                then
                    local settings = {
                        rust_analyzer = {
                            enabled = false,
                        },
                    }

                    vim.schedule(function()
                        -- consider all clients attached to the buffer, if any do not want inlay
                        -- hints then do not enable it
                        local enabled_on_attach = true
                        for _i, c in
                            ipairs(
                                vim.tbl_values(
                                    util.get_config_by_ft(vim.bo[ev.buf].filetype)
                                )
                            )
                        do
                            if
                                (settings[c.name] or {}).enabled ~= nil
                                and (settings[c.name] or {}).enabled == false
                            then
                                enabled_on_attach = false
                                break
                            end
                        end

                        vim.lsp.inlay_hint.enable(enabled_on_attach, { bufnr = ev.buf })
                    end)

                    nmap("<leader>th", function()
                        vim.lsp.inlay_hint.enable(
                            not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                            { bufnr = ev.buf }
                        )
                    end, "[T]oggle Inlay [H]ints", ev.buf)
                end

                local lsp_formatting_blocklist = {
                    ts_ls = true,
                    lua_ls = true,
                    rust_analyzer = true,
                }

                if
                    -- include all handler-related capabilities here
                    client.capabilities.experimental
                    and client.capabilities.experimental["serverStatusNotification"]
                then
                    setup_lsp_handlers(client)
                end

                -- continue only if we need LSP formatting
                if
                    not (client and client.server_capabilities.documentFormattingProvider)
                    or lsp_formatting_blocklist[client.name] ~= nil
                then
                    return
                end

                ---@param opts vim.lsp.buf.format.Opts
                local lsp_format = function(opts)
                    vim.lsp.buf.format(opts)
                end

                -- organize Go imports before write
                if client.name == "gopls" then
                    lsp_format = function(opts)
                        local enc =
                            vim.lsp.get_clients({ bufnr = ev.buf })[1].offset_encoding
                        local params = vim.lsp.util.make_range_params(nil, enc)
                        ---@diagnostic disable-next-line: inject-field
                        params.context = { only = { "source.organizeImports" } }

                        local timeout_ms = 1000
                        local result, _ = vim.lsp.buf_request_sync(
                            0,
                            "textDocument/codeAction",
                            params,
                            timeout_ms
                        )
                        for cid, res in pairs(result or {}) do
                            for _, r in pairs(res.result or {}) do
                                if r.edit then
                                    local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding
                                        or "utf-16"
                                    vim.lsp.util.apply_workspace_edit(r.edit, enc)
                                end
                            end
                        end
                        vim.lsp.buf.format(opts)
                    end
                end

                -- create a command `:Format` local to the LSP buffer
                vim.api.nvim_buf_create_user_command(ev.buf, "Format", function(_)
                    vim.schedule(function()
                        lsp_format({
                            async = true,
                            filter = function(c)
                                return c.id == client.id
                            end,
                        })
                    end)
                end, { desc = "Format current buffer with LSP" })

                -- manual format binding
                vim.keymap.set("n", "<leader>f", function()
                    vim.schedule(function()
                        lsp_format({
                            async = true,
                            filter = function(c)
                                return c.id == client.id
                            end,
                        })
                    end)
                end, {
                    buffer = ev.buf,
                    desc = "Format current buffer with LSP",
                })

                -- LSP autoformatting *before* saving file
                --
                -- if LSP client that is attaching to current buffer is in table `lsp_autoformat_clients`:
                -- if NOT NIL,
                --     enable autoformatting, creating the command `:AutoFormatOFF` to temporarily disable it
                -- if NIL,
                --     create the command `AutoFormatON` to temporarily enable autoformatting

                local lsp_autoformat_clients = {}

                ---@type function
                local enable_lsp_autoformatting
                ---@type function
                local create_autoformat_off_cmd
                ---@type function
                local create_autoformat_on_cmd

                ---@return number # The ID number of the autocommand that was just created
                enable_lsp_autoformatting = function()
                    return vim.api.nvim_create_autocmd("BufWritePre", {
                        group = id,
                        buffer = ev.buf,
                        callback = function()
                            lsp_format({
                                async = false, -- default
                                filter = function(c)
                                    return c.id == client.id
                                end,
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
                        { desc = "Disable automatic LSP formatting before saving" }
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
                            local ok, cmd = pcall(enable_lsp_autoformatting)
                            if ok then
                                create_autoformat_off_cmd(cmd)
                            end
                        end,
                        { desc = "Enable automatic LSP formatting before saving" }
                    )
                end

                if (lsp_autoformat_clients or {})[client.name] ~= nil then
                    local ok, cmd = pcall(enable_lsp_autoformatting)
                    if ok then
                        create_autoformat_off_cmd(cmd)
                    end
                else
                    create_autoformat_on_cmd()
                end
            end,
        })

        -- get supported LSP client capabilities that are implemented by Neovim
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend(
            "force",
            capabilities,
            require("blink-cmp").get_lsp_capabilities() -- additional capabilities from blink
        )

        ---@type table<string, vim.lsp.Config>
        local system_servers = {
            rust_analyzer = {
                -- TODO: write a handler for these colored rust_analyzer diagnostics
                -- capabilities = {
                --     experimental = {
                --         colorDiagnosticOutput = true,
                --     },
                -- },
                settings = {
                    ["rust-analyzer"] = {
                        check = {
                            command = "clippy", -- Important
                        },
                        lens = {
                            references = {
                                adt = {
                                    enable = true,
                                },
                                enumVariant = {
                                    enable = true,
                                },
                                method = {
                                    enable = true,
                                },
                                trait = {
                                    enable = true,
                                },
                            },
                        },
                        inlayHints = {
                            bindingModeHints = {
                                enable = true,
                            },
                            closureCaptureHints = {
                                enable = true,
                            },
                            closureReturnTypeHints = {
                                enable = true,
                            },
                            discriminantHints = {
                                enable = true,
                            },
                            expressionAdjustmentHints = {
                                enable = true,
                            },
                            genericParameterHints = {
                                lifetime = {
                                    enable = true,
                                },
                                type = {
                                    enable = true,
                                },
                            },
                            implicitDrops = {
                                enable = true,
                            },
                            implicitSizedBoundHints = {
                                enable = true,
                            },
                            lifetimeElisionHints = {
                                enable = true,
                                useParameterNames = true,
                            },
                            rangeExclusiveHints = {
                                enable = true,
                            },
                            reborrowHints = {
                                enable = true,
                            },
                        },
                        hover = {
                            memoryLayout = {
                                niches = true,
                                offset = "hexadecimal",
                                size = "both",
                            },
                            show = {
                                traitAssocItems = 5,
                                fields = 5,
                                enumVariants = 5,
                            },
                        },
                        imports = {
                            granularity = {
                                group = "module",
                                enforce = true,
                            },
                            prefix = "self",
                            preferNoStd = true,
                        },
                        completion = {
                            fullFunctionSignatures = {
                                enable = true,
                            },
                            -- show private items and fields even if they aren't visible
                            privateEditable = {
                                enable = true,
                            },
                        },
                        diagnostics = {
                            styleLints = {
                                enable = true,
                            },
                            warningsAsHint = {
                                "clippy::must_use_candidate",
                                "clippy::arithmetic_side_effects",
                                "clippy::cast_precision_loss",
                                "clippy::as_conversions",
                            },
                        },
                        cargo = {
                            -- pass `--all-features` to cargo commands
                            features = "all",
                            targetDir = true,
                        },
                        -- cachePriming = {
                        --     enable = true,
                        --     numThreads = 32 / 4,
                        -- },
                    },
                },
            },
        }

        ---@type table<string, vim.lsp.Config>
        local mason_servers = {
            lua_ls = {}, -- see: `.luarc.jsonc`
            jsonls = {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = { enable = true },
                    },
                },
            },
            yamlls = {
                settings = {
                    yaml = {
                        schemaStore = {
                            -- must disable built-in schemaStore to use schemaStore plugin
                            enable = false,
                            -- avoid TypeError
                            url = "",
                        },
                        schemas = require("schemastore").yaml.schemas(),
                    },
                },
            },
            gopls = {
                settings = {
                    completeUnimported = true,
                    usePlaceholders = true,
                    analyses = {
                        unusedvariable = true,
                        useany = true,
                    },
                    -- gofumpt = true,
                    -- staticcheck = true
                },
            },
            pyright = {},
            ts_ls = {
                settings = {
                    implicitProjectConfiguration = {
                        checkJs = true,
                    },
                },
            },
        }

        require("mason").setup({
            max_concurrent_installers = 10,
            ui = {
                icons = {
                    package_installed = "󰄳 ",
                    package_pending = " ",
                    package_uninstalled = "󰄯 ",
                },
            },
        })

        ---@param server_name string
        ---@param server_list table<string, table>
        local function setup_lsp_server(server_name, server_list)
            local server = server_list[server_name] or {}
            -- this handles overriding only values explicitly passed
            -- by the server configuration above
            server.capabilities =
                vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
        end

        local function mason_server_handler(mason_server_name)
            setup_lsp_server(mason_server_name, mason_servers)
        end

        -- installs packages to:
        -- ~/.local/share/nvim/mason/packages
        require("mason-lspconfig").setup({
            ensure_installed = vim.tbl_keys(mason_servers or {}),
            handlers = {
                mason_server_handler,
            },
        })
        for k, _v in pairs(system_servers or {}) do
            setup_lsp_server(k, system_servers or {})
        end
    end,
}
