local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

-- prevent wibox from obstructing fullscreen window clients
client.connect_signal("focus", function(c)
  if c.fullscreen then
    mouse.screen.mywibox:struts({ top = 0 })
  else
    mouse.screen.mywibox:struts(mouse.screen.mywibox_struts)
  end
end)
client.connect_signal("unmanage", function(c)
  if c.fullscreen then
    mouse.screen.mywibox:struts(mouse.screen.mywibox_struts)
  else
    mouse.screen.mywibox:struts({ top = 0 })
  end
end)

-- set upper limit for floating window
client.connect_signal("manage", function(c, context, hints)
  if c.floating and c.geometrySet == nil then
    local targetWidth = c.screen.geometry.width * 0.5
    local targetHeight = c.screen.geometry.height * 0.5

    if c.width > targetWidth then
      c.width = targetWidth
    end
    c.x = c.screen.geometry.x + (c.screen.geometry.width - c.width) * 0.5

    if c.height > targetHeight then
      c.height = targetHeight
    end
    c.y = c.screen.geometry.y + (c.screen.geometry.height - c.height) * 0.5

    c.geometrySet = true
  end
  awful.ewmh.client_geometry_requests(c, context, hints)
end)

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  local buttons = gears.table.join(
    awful.button({}, 1, function()
      c:emit_signal("request::activate", "titlebar", { raise = true })
      awful.mouse.client.move(c)
    end),
    awful.button({}, 3, function()
      c:emit_signal("request::activate", "titlebar", { raise = true })
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c):setup({
    { -- Left
      awful.titlebar.widget.iconwidget(c),
      buttons = buttons,
      layout = wibox.layout.fixed.horizontal,
    },
    { -- Middle
      { -- Title
        align = "center",
        widget = awful.titlebar.widget.titlewidget(c),
      },
      buttons = buttons,
      layout = wibox.layout.flex.horizontal,
    },
    { -- Right
      awful.titlebar.widget.floatingbutton(c),
      awful.titlebar.widget.maximizedbutton(c),
      awful.titlebar.widget.stickybutton(c),
      awful.titlebar.widget.ontopbutton(c),
      awful.titlebar.widget.closebutton(c),
      layout = wibox.layout.fixed.horizontal(),
    },
    layout = wibox.layout.align.horizontal,
  })
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
  c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
  c.border_color = beautiful.border_normal
end)

-- autostart
awesome.connect_signal("startup", function()
  awful.spawn.with_shell(xdg_config_home .. "/awesome/autorun.sh")
end)
