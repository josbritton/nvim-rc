return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter", "nvim-web-devicons" },
    config = function()
        local ts = require("nvim-treesitter")

        local t = vim.tbl_filter(function(lang)
            return not vim.tbl_contains(ts.get_installed(), lang)
        end, { "markdown", "markdown_inline", "html", "latex", "yaml" })

        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        local opts = {
            enabled = false,
            overrides = {
                buftype = {
                    nofile = {
                        enabled = true,
                    },
                },
            },
            html = {
                tag = {
                    code = {
                        scope_highlight = "RenderMarkdownCode",
                    },
                    strong = {
                        scope_highlight = "htmlBold",
                    },
                    em = {
                        scope_highlight = "@text.emphasis",
                    },
                },
            },
            code = {
                language = false,
                disable_background = true,
            },
        }

        local setup = function()
            require("render-markdown").setup(opts)
        end
        ts.install(t):await(setup)
    end,
    opts = {},
}
