vim.g.lazy_load_on_idle = true
PLUGINS = "josbritton.plugins"
CARGOMOD = "josbritton.cargo"
Notify = require("josbritton.notify")
-- start config
require("josbritton.options")
require("josbritton.theme")
require("josbritton.events")
require("josbritton.lazy")
require("josbritton.keymaps")
require("josbritton.commands")
Statusline = require("josbritton.statusline")
