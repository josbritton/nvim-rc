-- experimental Lua module loader
vim.loader.enable()

Notify = require("josbritton.notify")
-- start config
require("josbritton.options")
require("josbritton.theme")
require("josbritton.events")
require("josbritton.lazy")
require("josbritton.keymaps")
require("josbritton.statusline")
