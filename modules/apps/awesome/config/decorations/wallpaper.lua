local gears = require("gears")
local awful = require("awful")

local function scanDir(directory)
  local fileList = {}

  for filepath in io.popen('find -L "' .. directory .. "\" -type f -iregex '.*\\.\\(jpg\\|jpeg\\|png\\)'"):lines() do
    table.insert(fileList, filepath)
  end

  return fileList
end

local xdg_data_home = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
local wallpaperList = scanDir(xdg_data_home .. "/wallpapers")

local function setWallpaper(screen)
  local wallpaper = wallpaperList[math.random(1, #wallpaperList)]
  gears.wallpaper.maximized(wallpaper, screen, true)
end

math.randomseed(os.time())

awful.screen.connect_for_each_screen(function(s)
  setWallpaper(s)
end)

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", setWallpaper) -- luacheck: ignore
