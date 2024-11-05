local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
menubar.utils.terminal = RC.vars.terminal -- Set the terminal for applications that require it

local globalkeys = gears.table.join(awful.key({ RC.vars.modkey }, "p", function()
  menubar.show()
end, { description = "show the menubar", group = "launcher" }))

RC.globalkeys = gears.table.join(RC.globalkeys, globalkeys)
