local awful = require("awful")
local gears = require("gears")

local clientkeys = gears.table.join(
  awful.key({ RC.vars.modkey }, "z", function(c)
    c.maximized = not c.maximized
    c:raise()
  end, { description = "toggle maginify", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "z", function(c)
    c.fullscreen = not c.fullscreen
    c:raise()
  end, { description = "toggle maginify", group = "client" }),
  awful.key({ RC.vars.modkey }, "h", function()
    awful.client.focus.byidx(-1)
  end, { description = "focus previous by index", group = "client" }),
  awful.key({ RC.vars.modkey }, "j", function()
    awful.client.focus.byidx(1)
  end, { description = "focus next by index", group = "client" }),
  awful.key({ RC.vars.modkey }, "k", function()
    awful.client.focus.byidx(-1)
  end, { description = "focus previous by index", group = "client" }),
  awful.key({ RC.vars.modkey }, "l", function()
    awful.client.focus.byidx(1)
  end, { description = "focus next by index", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "h", function()
    awful.client.swap.byidx(-1)
  end, { description = "swap with previous client by index", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "j", function()
    awful.client.swap.byidx(1)
  end, { description = "swap with next client by index", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "k", function()
    awful.client.swap.byidx(-1)
  end, { description = "swap with previous client by index", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "l", function()
    awful.client.swap.byidx(1)
  end, { description = "swap with next client by index", group = "client" }),
  awful.key({ RC.vars.modkey, "Control" }, "h", function()
    awful.tag.incmwfact(-0.05)
  end, { description = "decrease master width factor", group = "layout" }),
  awful.key({ RC.vars.modkey, "Control" }, "l", function()
    awful.tag.incmwfact(0.05)
  end, { description = "increase master width factor", group = "layout" }),
  awful.key({ RC.vars.modkey }, "f", function(c)
    c.floating = not c.floating
    c.width = (c.screen.geometry.width * 0.5)
    c.height = (c.screen.geometry.height * 0.5)
    c.x = (c.screen.geometry.width - c.width) * 0.5
    c.y = (c.screen.geometry.height - c.height) * 0.5
  end, { description = "toggle floating", group = "client" }),
  awful.key({ RC.vars.modkey, "Shift" }, "q", function(c)
    c:kill()
  end, { description = "close", group = "client" }),
  awful.key({ RC.vars.modkey }, ";", function(c)
    c:move_to_screen()
  end, { description = "move to screen", group = "client" }),
  awful.key({ RC.vars.modkey }, "\\", function(c)
    c.ontop = not c.ontop
  end, { description = "toggle keep on top", group = "client" })
)

RC.clientkeys = clientkeys
