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
awful.rules.rules = {
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
      instance = {
        "DTA", -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
        "pinentry",
      },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin", -- kalarm.
        "SpeedCrunch",
        "Sxiv",
        "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
      },

      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester", -- xev.
        "rofi - Passphrase:", -- pinentry for rofi
      },
      role = {
        "AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        -- @todo this breaks PWAs
        -- "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
      },
    },
    properties = { floating = true },
  },

  -- Add titlebars to dialog clients
  {
    rule_any = { type = { "dialog" } },
    properties = { titlebars_enabled = true },
  },

  { rule = { class = "discord" }, properties = { screen = 2, tag = " 0 " } },
  { rule = { class = "WhatSie" }, properties = { screen = 2, tag = " 9 " } },

  { rule = { class = "Slack" }, properties = { screen = 2, tag = " 8 " } },

  { rule = { class = "TelegramDesktop" }, properties = { screen = 2, tag = " 7 " } },
  { rule = { class = "teams-pwa" }, properties = { screen = 2, tag = " 6 " } },

  { rule = { class = "thunderbird" }, properties = { screen = 2, tag = " 2 " } },
  { rule = { class = "obsidian" }, properties = { screen = 2, tag = " 3 " } },

  -- class will cover also quick add, which will get stuck to the tag 3
  {
    rule = { name = "Everdo" },
    except = { name = "Everdo Quick Capture" },
    properties = { screen = 2, tag = " 1 " },
  },

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- { rule = { class = "Firefox" },
  --   properties = { screen = 1, tag = "2" } },
}
-- }}}
