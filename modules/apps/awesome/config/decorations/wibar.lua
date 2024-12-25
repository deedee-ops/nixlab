local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

local build_local_widget = function(widget, color)
  return {
    {
      {
        {
          {
            widget = widget,
          },
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
          widget = wibox.container.margin,
        },
        shape = gears.shape.rounded_bar,
        fg = color,
        widget = wibox.container.background,
      },
      left = 10,
      right = 10,
      top = 0,
      bottom = 0,
      widget = wibox.container.margin,
    },
    layout = wibox.layout.fixed.horizontal,
  }
end

-- battery status
local widget_battery = wibox.widget({
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox,
})

local _, battery_signal = awful.widget.watch(xdg_config_home .. "/awesome/scripts/battery.sh", 30, function(_, stdout)
  widget_battery.text = stdout
end)

widget_battery:buttons(gears.table.join(
  awful.button({}, 1, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/battery.sh --toggle-hibernate", function() end)
    battery_signal:emit_signal("timeout")
  end)
))

local mybattery = build_local_widget(widget_battery, "#a6e3a2")

-- volume control
local widget_volume = wibox.widget({
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox,
})

local _, volume_signal = awful.widget.watch(xdg_config_home .. "/awesome/scripts/volume.sh", 1, function(_, stdout)
  widget_volume.text = stdout
end)

widget_volume:buttons(gears.table.join(
  awful.button({}, 1, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/volume.sh --toggle-output-mute", function() end)
    volume_signal:emit_signal("timeout")
  end),
  awful.button({}, 3, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/volume.sh --toggle-input-mute", function() end)
    volume_signal:emit_signal("timeout")
  end),
  awful.button({}, 4, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/volume.sh --up", function() end)
    volume_signal:emit_signal("timeout")
  end),
  awful.button({}, 5, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/volume.sh --down", function() end)
    volume_signal:emit_signal("timeout")
  end)
))

local myvolume = build_local_widget(widget_volume, "#f9e2af")

-- notifications sound and history
local widget_notifications = wibox.widget({
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox,
})

local _, notifications_signal = awful.widget.watch(
  xdg_config_home .. "/awesome/scripts/dunst-widget.sh show",
  60,
  function(_, stdout)
    widget_notifications.text = stdout
  end
)

widget_notifications:buttons(gears.table.join(
  awful.button({}, 1, function()
    awful.spawn.easy_async(xdg_config_home .. "/awesome/scripts/dunst-widget.sh toggle", function() end)
    notifications_signal:emit_signal("timeout")
  end),
  awful.button({}, 3, function()
    awful.spawn.easy_async("dunstctl history-pop", function() end)
  end)
))

local mynotifications = build_local_widget(widget_notifications, "#f38ba8")

-- textclock
local widget_textclock = wibox.widget.textclock()

local mytextclock = build_local_widget(widget_textclock, "#cba6f7")

awful.screen.connect_for_each_screen(function(s)
  local mylayoutbox = awful.widget.layoutbox(s)
  mylayoutbox:buttons(gears.table.join(
    awful.button({}, 1, function()
      awful.layout.inc(1)
    end),
    awful.button({}, 3, function()
      awful.layout.inc(-1)
    end),
    awful.button({}, 4, function()
      awful.layout.inc(1)
    end),
    awful.button({}, 5, function()
      awful.layout.inc(-1)
    end)
  ))

  if RC.vars.useDunst then
    s.mytextnotifications = mynotifications
  end
  if RC.vars.showBattery then
    s.mytextbattery = mybattery
  end
  s.mytextvolume = myvolume
  s.mytextclock = mytextclock
  s.mylayoutbox = mylayoutbox
end)
