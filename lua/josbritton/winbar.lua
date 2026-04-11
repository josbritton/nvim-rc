function _G.aerial_winbar()
    local ok, aerial = pcall(require, "aerial")
    if not ok then
        return ""
    end
    local symbols = aerial.get_location(true)
    local hl = require("aerial.highlight")
    local parts = {}
    for _, s in ipairs(symbols) do
        local ig = hl.get_highlight(s, true, false)
        local ng = hl.get_highlight(s, false, false)
        local icon = ig and ("%#" .. ig .. "#" .. s.icon .. "%*") or s.icon
        local name = ng and ("%#" .. ng .. "#" .. s.name:gsub("%%", "%%%%") .. "%*")
            or s.name:gsub("%%", "%%%%")
        parts[#parts + 1] = icon .. " " .. name
    end
    return table.concat(parts, "%#NonText# ⟩ %*")
end

vim.o.winbar = "%{%v:lua.aerial_winbar()%}"
