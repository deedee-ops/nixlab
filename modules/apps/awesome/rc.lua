-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local dpi = require("beautiful").xresources.apply_dpi

RC = {
  globalkeys = {},
  globalbuttons = {},
  clientkeys = {},
  clientbuttons = {},
}
RC.vars = require("main.user-variables")

if RC.vars.useDunst then
  package.loaded["naughty.dbus"] = {}
end

require("main.error-handling")
require("main.layouts")
require("main.signals")
require("main.tags")

require("bindings.globalkeys")
require("bindings.globalbuttons")
require("bindings.clientkeys")
require("bindings.clientbuttons")

require("decorations.theme")
require("decorations.wallpaper")
require("decorations.wibar")

-- Global Mouse and keyboard bindings
root.keys(RC.globalkeys)
root.buttons(RC.globalbuttons)

awful.screen.set_auto_dpi_enabled(true)

-- {{{ Wibar
local tasklist_buttons = gears.table.join(
  awful.button({}, 1, function(c)
    if c == client.focus then
      c.minimized = true
    else
      c:emit_signal("request::activate", "tasklist", { raise = true })
    end
  end),
  awful.button({}, 4, function()
    awful.client.focus.byidx(1)
  end),
  awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
  end)
)

awful.screen.connect_for_each_screen(function(s)
  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()

  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist({
    screen = s,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = tasklist_buttons,
  })

  -- Create the wibox
  s.mywibox = awful.wibar({
    position = "top",
    border_width = 0,
    border_color = "#00000000",
    height = dpi(26),
    screen = s,
  })
  s.mywibox_struts = s.mywibox:struts()

  -- Add widgets to the wibox
  s.mywibox:setup({
    layout = wibox.layout.align.horizontal,
    { -- Left widgets
      layout = wibox.layout.fixed.horizontal,
      s.mytaglist,
      s.mypromptbox,
    },
    s.mytasklist, -- Middle widget
    { -- Right widgets
      layout = wibox.layout.fixed.horizontal,
      s.mytextupdates,
      s.mytextvolume,
      s.mytextnotifications,
      s.mytextbattery,
      wibox.widget({ markup = "|", widget = wibox.widget.textbox }),
      wibox.widget.systray(),
      wibox.widget({ markup = "| ", widget = wibox.widget.textbox }),
      s.mytextclock,
      s.mylayoutbox,
    },
  })
end)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = gears.table.join({
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = RC.clientkeys,
      buttons = RC.clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
      maximized_vertical = false,
      maximized_horizontal = false,
      floating = false,
      maximized = false,
    },
  },

  -- Floating clients.
  {
    rule_any = {
      instance = RC.vars.floatingInstance,
      class = RC.vars.floatingClass,
      name = RC.vars.floatingName,
      role = RC.vars.floatingRole,
    },
    properties = { floating = true },
  },
  -- Always on top on all desktops floating clients
  {
    rule_any = {
      instance = RC.vars.forcedFloatingInstance,
      class = RC.vars.forcedFloatingClass,
      name = RC.vars.forcedFloatingName,
      role = RC.vars.forcedFloatingRole,
    },
    properties = { floating = true, ontop = true, focus = true, sticky = true },
  },

  -- Add titlebars to dialog clients
  {
    rule_any = { type = { "dialog" } },
    properties = { titlebars_enabled = true },
  },
}, RC.vars.extraAwfulRules)

-- }}}
