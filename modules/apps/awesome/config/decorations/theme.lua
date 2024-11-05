local beautiful = require("beautiful")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local themes_path = gears.filesystem.get_themes_dir()

beautiful.init(themes_path .. "default/theme.lua")

-- https://elv13.github.io/documentation/06-appearance.md.html
--beautiful.font = "xft:JetBrainsMono Nerd Font Mono:style=Regular:size=10"
beautiful.font = "JetBrainsMono Nerd Font Mono Regular 10"
beautiful.useless_gap = dpi(6)
beautiful.border_width = dpi(1)

beautiful.bg_normal = "#1e1e2e"
beautiful.bg_focus = "#1e1e2e"
beautiful.bg_urgent = "#1e1e2e"
beautiful.bg_minimize = "#1e1e2e"
beautiful.bg_systray = beautiful.bg_normal

beautiful.fg_normal = "#585b70"
beautiful.fg_focus = "#fab387"
beautiful.fg_urgent = "#f38ba8"
beautiful.fg_minimize = "#ffffff"

beautiful.border_normal = "#313244"
beautiful.border_focus = "#b4befe"
beautiful.border_marked = "#fab387"

-- remove little squares on taglist
beautiful.taglist_squares_sel = nil
beautiful.taglist_squares_unsel = nil

-- recolor layout tiles
beautiful.layout_fairv = gears.color.recolor_image(themes_path .. "/default/layouts/fairv.png", beautiful.fg_focus)
beautiful.layout_max = gears.color.recolor_image(themes_path .. "/default/layouts/max.png", beautiful.fg_focus)
