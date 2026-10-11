--!nonstrict
-- Bar widget: glyph + number of open todos. Left click toggles the panel
-- (declared in plugin.toml as a [widget.actions] default), right click syncs.

local SNAPSHOT_KEY = "todo.snapshot"
local CMD_KEY = "todo.cmd"
local OPEN_KEY = "todo.panelOpen"

local snapshot = noctalia.state.get(SNAPSHOT_KEY)
local open = noctalia.state.get(OPEN_KEY) == true

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

local function render()
  local s = snapshot or { openCount = 0, status = "idle", pending = 0 }
  local count = s.openCount or 0

  barWidget.setGlyph(noctalia.getConfig("glyph"))
  if s.status == "error" then
    barWidget.setGlyphColor("error")
  else
    barWidget.setGlyphColor(open and "primary" or "on_surface")
  end
  local showCount = noctalia.getConfig("show_count") ~= false
  barWidget.setText(if showCount and count > 0 then tostring(count) else "")

  local syncText
  if s.status == "error" then
    syncText = s.error
  elseif s.status == "offline" then
    syncText = tr("status.offline", { count = s.pending or 0 })
  elseif s.status == "unconfigured" then
    syncText = tr("status.unconfigured")
  elseif (s.lastSync or 0) > 0 then
    syncText = tr("status.synced", { time = os.date("%H:%M", s.lastSync) })
  else
    syncText = tr("status.syncing")
  end
  barWidget.setTooltip({
    { tr("title"), tr("tooltip.open", { count = count }) },
    { tr("tooltip.sync"), syncText },
  })
end

noctalia.state.watch(SNAPSHOT_KEY, function(value)
  snapshot = value
  render()
end)

noctalia.state.watch(OPEN_KEY, function(value)
  open = value == true
  render()
end)

function onRightClick()
  noctalia.state.set(CMD_KEY, { action = "sync", at = noctalia.nowMs() })
end

function update()
  render()
end

noctalia.setUpdateInterval(60000)
render()
