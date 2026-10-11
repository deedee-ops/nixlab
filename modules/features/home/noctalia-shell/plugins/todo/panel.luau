--!nonstrict
-- Panel: quick-add input on top, then the list. Click a todo (or its box) to
-- mark it done / not done, the trash button removes it. Todos containing URLs
-- get a link button: one URL opens directly, several expand into a list (or a
-- menu on right click). All todo state lives in the sync service; this only
-- renders its snapshot and sends commands.
--
-- Keyboard (capture_keys in plugin.toml): the panel opens in "input" mode with
-- the add field focused; Enter adds. Down moves into "list" mode, which drops
-- the field from the tree so Space reaches onKey (a focused text field always
-- gets printable keys). In the list: Up/Down move the highlight, Space ticks,
-- Enter opens the link (or unfolds several, navigated with Up/Down). Up on the
-- first todo brings the field back.

local links = require("./lib/links.luau")

local SNAPSHOT_KEY = "todo.snapshot"
local CMD_KEY = "todo.cmd"
local OPEN_KEY = "todo.panelOpen"

-- Row width budget: a ui.button label only wraps when the button has an
-- explicit width, so the text gets whatever the fixed parts leave over.
local PANEL_WIDTH = 920 -- keep in sync with [[panel]] width in plugin.toml
local PANEL_PADDING = 14 -- Style::panelPadding, left and right
local SCROLLBAR_GUTTER = 14 -- Style::scrollbarWidth + Style::scrollbarGap
local ROW_GAP = 4
local GLYPH_BTN_W = 30 -- ghost glyph button: 2 × Style::spaceSm + a 14px glyph
local TEXT_WIDTH = PANEL_WIDTH - 2 * PANEL_PADDING - SCROLLBAR_GUTTER - 2 * (GLYPH_BTN_W + ROW_GAP)
local LINK_INDENT = GLYPH_BTN_W + ROW_GAP -- link list lines up with the todo text
-- Building a row costs real CPU under noctalia's per-callback budget; open
-- todos come first in the snapshot, so the cap only hides old done ones.
local MAX_ROWS = 100
local HIGHLIGHT = "primary/0.15"
local NO_FILL = "#00000000"

local snapshot = noctalia.state.get(SNAPSHOT_KEY)
local isOpen = false
local inputRev = 0
local draft = ""
local expandedUid = nil -- todo whose link list is unfolded
local urlCache = {} -- summary -> urls, so renders don't rescan every todo

-- keyboard navigation
local mode = "input" -- "input" | "list"
local selectedUid = nil
local selectedIndex = 1 -- where the highlight was, for when its todo vanishes
local linkIndex = nil -- highlighted entry of the unfolded link list

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

local function send(action, fields)
  local cmd = fields or {}
  cmd.action = action
  cmd.at = noctalia.nowMs() -- makes repeated identical commands distinct values
  noctalia.state.set(CMD_KEY, cmd)
end

-- Combining long stroke overlay: there is no strike-through text prop.
local function strike(text)
  if text == "" or utf8.len(text) == nil then
    return text
  end
  local out = {}
  for _, code in utf8.codes(text) do
    table.insert(out, utf8.char(code))
    table.insert(out, "\u{0336}")
  end
  return table.concat(out)
end

local function statusLine(s)
  if s.status == "unconfigured" then
    return tr("status.unconfigured"), "on_surface_variant"
  elseif s.status == "error" then
    return s.error, "error"
  elseif s.status == "offline" then
    return tr("status.offline", { count = s.pending or 0 }), "on_surface_variant"
  elseif s.status == "syncing" then
    return tr("status.syncing"), "on_surface_variant"
  end
  return nil, nil
end

local function urlsOf(summary)
  local urls = urlCache[summary]
  if urls == nil then
    urls = links.extract(summary)
    urlCache[summary] = urls
  end
  return urls
end

-- Todos as shown: done ones hidden unless enabled, capped at MAX_ROWS.
-- Returns the visible items and how many more were cut off by the cap.
local function visibleItems()
  local showDone = noctalia.getConfig("show_completed") == true
  local items = {}
  local hidden = 0
  for _, item in (snapshot and snapshot.items or {}) do
    if showDone or not item.done then
      if #items < MAX_ROWS then
        table.insert(items, item)
      else
        hidden += 1
      end
    end
  end
  return items, hidden
end

local function findItem(uid)
  for _, item in (snapshot and snapshot.items or {}) do
    if item.uid == uid then
      return item
    end
  end
  return nil
end

local render -- forward declaration

local function add(text)
  if noctalia.string.trim(text or "") == "" then
    return
  end
  send("add", { text = text })
  draft = ""
  inputRev += 1 -- fresh key: clears the field and focuses it again
  render()
end

-- Hands the URL to the desktop's default handler, then gets out of the way so
-- the browser can take keyboard focus.
local function openUrl(url)
  local opener = if noctalia.commandExists("xdg-open") then { "xdg-open", url }
    elseif noctalia.commandExists("gio") then { "gio", "open", url }
    else nil
  if opener == nil or not noctalia.runAsync(opener) then
    noctalia.notifyError(tr("title"), tr("error.open_link", { url = url }))
    return
  end
  expandedUid = nil
  linkIndex = nil
  panel.close()
end

local function resetToInput()
  mode = "input"
  selectedUid = nil
  linkIndex = nil
  inputRev += 1 -- recreated field grabs focus again; `draft` seeds its text
end

local function enterInputMode()
  resetToInput()
  render()
end

-- Keeps the highlight on a visible todo: when the selected one vanished
-- (ticked with done todos hidden, deleted, ...), take whatever now sits at
-- its old position. Returns the visible items, the hidden count and the
-- selected index (nil outside list mode).
local function syncSelection()
  local items, hidden = visibleItems()
  if mode ~= "list" then
    return items, hidden, nil
  end
  for index, item in items do
    if item.uid == selectedUid then
      selectedIndex = index
      return items, hidden, index
    end
  end
  if #items == 0 then
    resetToInput()
    return items, hidden, nil
  end
  selectedIndex = math.clamp(selectedIndex, 1, #items)
  selectedUid = items[selectedIndex].uid
  linkIndex = nil
  return items, hidden, selectedIndex
end

-- ── rendering ───────────────────────────────────────────────────────────────

local function linkButton(item, urls)
  if #urls == 1 then
    return ui.button({
      glyph = "external-link",
      variant = "ghost",
      tooltip = links.shorten(urls[1], 80),
      onClick = function()
        openUrl(urls[1])
      end,
    })
  end
  local expanded = expandedUid == item.uid
  return ui.button({
    glyph = "external-link",
    variant = "ghost",
    selected = expanded,
    tooltip = tr("tip.links", { count = #urls }),
    onClick = function()
      expandedUid = if expanded then nil else item.uid
      linkIndex = nil
      render()
    end,
    -- native menu needs the pointer of a right click, so it lives here
    onRightClick = function()
      local items = { { kind = "header", label = tr("menu.links") } }
      for index, url in urls do
        table.insert(items, { id = tostring(index), label = links.shorten(url, 90) })
      end
      panel.openContextMenu({ items = items, onActivate = "onLinkMenuAction", context = item.uid })
    end,
  })
end

local function linkKey(item, index)
  return "link-" .. item.uid .. "-" .. index
end

local function linkList(item, urls, highlighted)
  local entries = {}
  for index, url in urls do
    table.insert(entries, ui.button({
      key = linkKey(item, index),
      glyph = "link",
      text = links.shorten(url, 90),
      variant = "ghost",
      controlSize = "sm",
      contentAlign = "start",
      selected = highlighted == index,
      tooltip = url,
      onClick = function()
        openUrl(url)
      end,
    }))
  end
  return ui.column({ key = "links-" .. item.uid, gap = 0, paddingH = LINK_INDENT }, entries)
end

local function rowKey(item)
  return "row-" .. item.uid .. (item.done and "-done" or "")
end

local function todoRow(item, selected)
  local function toggle()
    send("toggle", { uid = item.uid })
  end
  local urls = urlsOf(item.summary)
  local children = {
    ui.button({
      glyph = item.done and "square-check" or "square",
      variant = "ghost",
      tooltip = tr(item.done and "tip.undone" or "tip.done"),
      onClick = toggle,
    }),
    ui.button({
      text = item.done and strike(item.summary) or item.summary,
      variant = "ghost",
      contentAlign = "start",
      width = TEXT_WIDTH - (if #urls > 0 then GLYPH_BTN_W + ROW_GAP else 0),
      opacity = item.done and 0.55 or 1,
      onClick = toggle,
    }),
  }
  if #urls > 0 then
    table.insert(children, linkButton(item, urls))
  end
  table.insert(children, ui.button({
    glyph = "trash",
    variant = "ghost",
    tooltip = tr("tip.delete"),
    onClick = function()
      send("delete", { uid = item.uid })
    end,
  }))
  local row = ui.row({
    key = rowKey(item),
    gap = ROW_GAP,
    align = "center",
    radius = 6,
    -- the todo row itself is highlighted unless a link inside it is
    fill = if selected and linkIndex == nil then HIGHLIGHT else NO_FILL,
  }, children)
  if #urls > 1 and expandedUid == item.uid then
    local highlighted = if selected then linkIndex else nil
    return ui.column({ key = "todo-" .. item.uid .. "-links", gap = 0 }, { row, linkList(item, urls, highlighted) })
  end
  return row
end

function render()
  if not isOpen then
    return
  end
  local s = snapshot or { items = {}, status = "idle" }
  local items, hidden, selIndex = syncSelection()

  local header = ui.row({ gap = 4, align = "center" }, {
    ui.label({ text = tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
    ui.button({
      glyph = "refresh",
      variant = "ghost",
      enabled = s.status ~= "syncing",
      tooltip = tr("tip.sync"),
      onClick = function()
        send("sync")
      end,
    }),
    ui.button({ glyph = "settings", variant = "ghost", tooltip = tr("tip.settings"), onClick = "onOpenSettings" }),
    ui.button({ glyph = "close", variant = "ghost", tooltip = tr("tip.close"), onClick = "onClosePanel" }),
  })

  local top
  if mode == "input" then
    top = ui.row({ key = "input-row", gap = 8, align = "center" }, {
      ui.input({
        key = "new-" .. inputRev,
        value = draft,
        placeholder = tr("placeholder"),
        focus = true,
        flexGrow = 1,
        onChange = function(value)
          draft = value
        end,
        onSubmit = add, -- Enter is captured by onKey; kept as a fallback
      }),
      ui.button({
        glyph = "plus",
        variant = "primary",
        tooltip = tr("tip.add"),
        onClick = function()
          add(draft)
        end,
      }),
    })
  else
    -- no text field in the tree, so Space reaches onKey
    top = ui.row({
      key = "list-hint",
      gap = 8,
      align = "center",
      onClick = enterInputMode,
      tooltip = tr("tip.back_to_input"),
    }, {
      ui.glyph({ name = "keyboard", size = 14, color = "on_surface_variant" }),
      ui.label({ text = tr("hint.list"), color = "on_surface_variant", fontSize = 12, flexGrow = 1 }),
    })
  end

  local parts = { header, top }

  local text, color = statusLine(s)
  if text ~= nil and text ~= "" then
    table.insert(parts, ui.label({ text = text, color = color, fontSize = 12, maxWidth = PANEL_WIDTH - 2 * PANEL_PADDING }))
  end

  if #items == 0 then
    table.insert(parts, ui.column({ flexGrow = 1, align = "center", justify = "center" }, {
      ui.label({ text = tr("empty"), color = "on_surface_variant" }),
    }))
  else
    local rows = {}
    local reveal = nil
    for index, item in items do
      local selected = index == selIndex
      table.insert(rows, todoRow(item, selected))
      if selected then
        reveal = if linkIndex ~= nil then linkKey(item, linkIndex) else rowKey(item)
      end
    end
    if hidden > 0 then
      table.insert(rows, ui.label({ key = "more", text = tr("more", { count = hidden }), color = "on_surface_variant", fontSize = 12 }))
    end
    table.insert(parts, ui.scroll({ flexGrow = 1, gap = 2, revealKey = reveal }, rows))
  end

  panel.render(ui.column({ flexGrow = 1, gap = 12 }, parts))
end

-- ── keyboard ────────────────────────────────────────────────────────────────

local function select(items, index)
  selectedUid = items[index].uid
  selectedIndex = index
  linkIndex = nil
end

local function onDown(items, index)
  if mode == "input" then
    if #items > 0 then
      mode = "list"
      select(items, 1)
    end
    return
  end
  local item = items[index]
  local urls = urlsOf(item.summary)
  if expandedUid == item.uid and #urls > 1 then
    if linkIndex == nil then
      linkIndex = 1
      return
    elseif linkIndex < #urls then
      linkIndex += 1
      return
    end
  end
  if index < #items then
    if expandedUid == item.uid then
      expandedUid = nil -- leaving the unfolded list folds it
    end
    select(items, index + 1)
  end
end

local function onUp(items, index)
  if mode ~= "list" then
    return
  end
  if linkIndex ~= nil then
    linkIndex = if linkIndex > 1 then linkIndex - 1 else nil
    return
  end
  if expandedUid == items[index].uid then
    expandedUid = nil
  end
  if index > 1 then
    select(items, index - 1)
  else
    resetToInput()
  end
end

local function onEnter(items, index)
  if mode == "input" then
    add(draft)
    return
  end
  local urls = urlsOf(items[index].summary)
  if linkIndex ~= nil then
    openUrl(urls[linkIndex])
  elseif #urls == 1 then
    openUrl(urls[1])
  elseif #urls > 1 then
    expandedUid = items[index].uid
    linkIndex = 1
  end
end

local function onSpace(items, index)
  if mode ~= "list" then
    return
  end
  local item = items[index]
  if linkIndex ~= nil then
    openUrl(urlsOf(item.summary)[linkIndex])
  else
    send("toggle", { uid = item.uid })
  end
end

-- keys are the capture_keys entries from plugin.toml, verbatim
local HANDLERS = { up = onUp, down = onDown, space = onSpace, ["return"] = onEnter, kp_enter = onEnter }

function onKey(chord, pressed)
  local handler = HANDLERS[chord]
  if not pressed or handler == nil or not isOpen then
    return
  end
  local items, _, index = syncSelection()
  if mode == "list" and index == nil then
    return
  end
  handler(items, index)
  render()
end

-- ── lifecycle & host callbacks ──────────────────────────────────────────────

noctalia.state.watch(SNAPSHOT_KEY, function(value)
  snapshot = value
  render()
end)

function onOpen(_context)
  isOpen = true
  mode = "input"
  selectedUid = nil
  linkIndex = nil
  snapshot = noctalia.state.get(SNAPSHOT_KEY)
  noctalia.state.set(OPEN_KEY, true)
  render()
end

function onClose()
  isOpen = false
  expandedUid = nil
  noctalia.state.set(OPEN_KEY, false)
end

-- Right-click menu of a multi-link todo: action ids are 1-based URL indices.
function onLinkMenuAction(actionId, uid)
  local item = findItem(uid)
  local url = item and urlsOf(item.summary)[tonumber(actionId)]
  if url ~= nil then
    openUrl(url)
  end
end

function onOpenSettings()
  noctalia.openSettings()
end

function onClosePanel()
  panel.close()
end
