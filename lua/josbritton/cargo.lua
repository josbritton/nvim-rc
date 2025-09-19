--- @module "blink.cmp"
--- @class blink.cmp.Source
local source = {}

---@type table<string, table<string, string[]>>
Cache = {}

-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = opts
    return self
end

-- (Optional) Enable the source in specific contexts only
function source:enabled()
    return vim.bo.filetype == "toml" and vim.endswith(vim.fn.bufname(), "Cargo.toml")
end

function source:get_completions(ctx, callback)
    -- ctx (context) contains the current keyword, cursor position, bufnr, etc.

    -- You should never filter items based on the keyword, since blink.cmp will
    -- do this for you

    ---@type vim.SystemObj
    local proc

    local path = vim.fn.fnamemodify(vim.fn.bufname(ctx.bufnr), ":p:h")

    ---@param res vim.SystemCompleted
    local on_exit = function(res)
        ---@type table<string, string[]>
        local t = {}
        for s in vim.gsplit(res.stdout or "", "\n") do
            local crate = (s:sub(1, (s:find(" ") or (#s + 1)) - 1)):match("^%s*(.*%S)")
                or nil
            if crate then
                t[crate] = vim.split(s, ";")
            end
        end

        -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem
        --- @type blink.cmp.CompletionItem[]
        local items = {}
        for k, v in pairs(t) do
            local detail = v[1]:sub(#k + 2, #v[1])
            local ver = detail:sub(1, (detail:find(" ") or (#detail + 1)) - 1)

            --- @type blink.cmp.CompletionItem
            local item = {
                -- Label of the item in the UI
                label = k,
                -- (Optional) Item kind, where `Function` and `Method` will receive
                -- auto brackets automatically
                kind = require("blink.cmp.types").CompletionItemKind.Module,
                exact = true,
                -- kind_name = "Crate",
                labelDetails = {
                    description = #ver > 14 and ("%s..."):format(ver:sub(1, 14)) or ver,
                },
                score_offset = -100,

                -- Text to be inserted when accepting the item using ONE of:
                --
                -- (Recommended) Control the exact range of text that will be replaced
                textEdit = {
                    newText = k,
                    range = {
                        -- 0-indexed line and character, end-exclusive
                        start = {
                            line = ctx.bounds.line_number - 1,
                            character = ctx.bounds.start_col - 1,
                        },
                        ["end"] = {
                            line = ctx.bounds.line_number - 1,
                            character = ctx.bounds.start_col + ctx.bounds.length - 1,
                        },
                    },
                },
                documentation = {
                    kind = "markdown",
                    value = ("%s `%s` %s\n\n---\nlib: *%s*\nrepo url: <%s>\nfeat: %s"):format(
                        k,
                        ver,
                        detail:sub(#ver + 2, #detail),
                        v[2],
                        v[3],
                        v[4]
                    ),
                    draw = nil,
                },
            }
            table.insert(items, item)
        end

        -- The callback _MUST_ be called at least once. The first time it's called,
        -- blink.cmp will show the results in the completion menu. Subsequent calls
        -- will append the results to the menu to support streaming results.
        --
        -- NOTE: blink.cmp will mutate the items you return, so you must vim.deepcopy them
        -- before returning if you want to re-use them in the future (such as for caching)
        ---@type blink.cmp.CompletionResponse
        local resp = {
            items = vim.deepcopy(items),
            -- Whether blink.cmp should request items when deleting characters
            -- from the keyword (i.e. "foo|" -> "fo|")
            -- Note that any non-alphanumeric characters will always request
            -- new items (excluding `-` and `_`)
            is_incomplete_backward = false,
            -- Whether blink.cmp should request items when adding characters
            -- to the keyword (i.e. "fo|" -> "foo|")
            -- Note that any non-alphanumeric characters will always request
            -- new items (excluding `-` and `_`)
            is_incomplete_forward = false,
        }
        callback(resp)
    end

    callback(Cache[path] or nil)
    -- get new data even if cache exists
    proc = vim.system({
        "cargo",
        "tree",
        "--prefix",
        "none",
        "--frozen",
        "--target",
        "all",
        "-f",
        "{p};{lib};{r};{f}",
    }, { timeout = 5000 }, on_exit)

    -- (Optional) Return a function which cancels the request
    -- If you have long running requests, it's essential you support cancellation
    return function()
        proc:kill(9)
    end
end

return source
