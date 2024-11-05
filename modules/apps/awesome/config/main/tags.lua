-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi

local globalkeys = {}
for i = 0, 9 do
  globalkeys = gears.table.join(
    globalkeys,
    -- View tag only.
    awful.key({ RC.vars.modkey }, tostring(i), function()
      local screen = awful.screen.focused()
      local tag = screen.tags[i == 0 and 10 or i]
      if tag then
        tag:view_only()
      end
    end, { description = "view tag #" .. i, group = "tag" }),
    -- Move client to tag.
    awful.key({ RC.vars.modkey, "Shift" }, tostring(i), function()
      if client.focus then
        local tag = client.focus.screen.tags[i == 0 and 10 or i]
        if tag then
          client.focus:move_to_tag(tag)
        end
      end
    end, { description = "move focused client to tag #" .. i, group = "tag" })
  )
end
RC.globalkeys = gears.table.join(RC.globalkeys, globalkeys)

local taglist_buttons = gears.table.join(
  awful.button({}, 1, function(t)
    t:view_only()
  end),
  awful.button({}, 3, awful.tag.viewtoggle),
  awful.button({}, 4, function(t)
    awful.tag.viewnext(t.screen)
  end),
  awful.button({}, 5, function(t)
    awful.tag.viewprev(t.screen)
  end)
)

local unfocus_icon = " "
local unfocus_color = "#585b70"

local empty_icon = " "
local empty_color = "#585b70"

local focus_icon = " "
local focus_color = "#b4befe"

local update_tags = function(self, c3)
  local tagicon = self:get_children_by_id("icon_role")[1]
  if c3.selected then
    tagicon.text = focus_icon
    self.fg = focus_color
  elseif #c3:clients() == 0 then
    tagicon.text = empty_icon
    self.fg = empty_color
  else
    tagicon.text = unfocus_icon
    self.fg = unfocus_color
  end
end

awful.screen.connect_for_each_screen(function(s)
  local layouts = {
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
  }

  -- Each screen has its own tag table.
  awful.tag({ " 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 ", " 0 " }, s, layouts)

  -- Create a taglist widget
  s.mytaglist = awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    layout = { spacing = 0, layout = wibox.layout.fixed.horizontal },
    buttons = taglist_buttons,
    widget_template = {
      {
        { id = "icon_role", font = "JetBrainsMono Nerd Font 12", widget = wibox.widget.textbox },
        id = "margin_role",
        top = dpi(0),
        bottom = dpi(0),
        left = dpi(2),
        right = dpi(2),
        widget = wibox.container.margin,
      },
      id = "background_role",
      widget = wibox.container.background,
      create_callback = function(self, c3, _index, _objects)
        update_tags(self, c3)
      end,

      update_callback = function(self, c3, _index, _objects)
        update_tags(self, c3)
      end,
    },
    --widget_template = {
    --update_callback = function(self, c3, index, objects)
    --self:get_children_by_id('index_role')[1].markup = '[ '..index..' ]'
    --end,
    --}
  })
end)
