local awful = require("awful")
local gears = require("gears")

local globalbuttons = gears.table.join(awful.button({}, 4, awful.tag.viewnext), awful.button({}, 5, awful.tag.viewprev))

RC.globalbuttons = gears.table.join(RC.globalbuttons, globalbuttons)
