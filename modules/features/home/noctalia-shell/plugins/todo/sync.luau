--!nonstrict
-- Headless service: owns the todo list and syncs it with a CalDAV calendar.
--
-- The list is cached in the plugin data dir, so the panel works offline and
-- across restarts. Local edits (add / toggle / delete) apply immediately and
-- are queued (`dirty` items, `tombstones`) until the next successful push.
-- Every sync pushes the queue first, then pulls: a cheap getetag REPORT, and a
-- calendar-multiget only for objects whose etag changed. On conflict the
-- local, not-yet-pushed edit wins.
--
-- Talks to the other entries through noctalia.state: publishes SNAPSHOT_KEY,
-- consumes commands from CMD_KEY. IPC events: `add <text>`, `sync`.

local caldav = require("./lib/caldav.luau")
local ical = require("./lib/ical.luau")
local xml = require("./lib/xml.luau")

local SNAPSHOT_KEY = "todo.snapshot"
local CMD_KEY = "todo.cmd"
local CONTINUE_KEY = "todo.sync.continue"
-- noctalia aborts any callback that burns more than 25 ms of CPU, and its
-- budget hook makes Luau far slower than usual, so big responses are parsed a
-- slice at a time (see defer) and objects are fetched in small batches.
local MULTIGET_BATCH = 10
local RESPONSES_PER_SLICE = 100
local OFFLINE_RETRY_SECONDS = 60
local DB_VERSION = 1

local dataDir = noctalia.pluginDataDir()
local dbPath = dataDir .. "/todos.json"

-- items: { uid, href?, etag, ics, summary, done, created, completed, dirty, new, rev }
local db = { version = DB_VERSION, account = "", calendarUrl = "", items = {}, tombstones = {} }

local status = "idle" -- idle | syncing | ok | offline | error | unconfigured
local errorText = ""
local lastSync = 0
local syncing = false
local again = false
local nextSyncAt = 0

local function trim(s)
  return noctalia.string.trim(s or "")
end

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

-- ── deferred work ───────────────────────────────────────────────────────────

-- Runs fn in a fresh callback (with a fresh CPU budget): the service watches
-- its own CONTINUE_KEY, and every state.set queues one watcher call.
local continuations = {}
local continueSeq = 0

local function defer(fn)
  table.insert(continuations, fn)
  continueSeq += 1
  noctalia.state.set(CONTINUE_KEY, continueSeq)
end

noctalia.state.watch(CONTINUE_KEY, function()
  local fn = table.remove(continuations, 1)
  if fn ~= nil then
    fn()
  end
end)

-- ── persistence ─────────────────────────────────────────────────────────────

local function load()
  local raw = noctalia.readFile(dbPath)
  if raw == nil or raw == "" then
    return
  end
  local decoded = noctalia.json.decode(raw)
  if type(decoded) ~= "table" or decoded.version ~= DB_VERSION then
    return
  end
  db.account = decoded.account or ""
  db.calendarUrl = decoded.calendarUrl or ""
  db.items = type(decoded.items) == "table" and decoded.items or {}
  db.tombstones = type(decoded.tombstones) == "table" and decoded.tombstones or {}
  for _, item in db.items do
    item.rev = item.rev or 0
  end
end

local function save()
  local encoded = noctalia.json.encode(db)
  if encoded == nil then
    return
  end
  local tmp = dbPath .. ".tmp"
  if noctalia.writeFile(tmp, encoded) then
    noctalia.renameFile(tmp, dbPath)
  end
end

-- ── snapshot for the widget and panel ───────────────────────────────────────

local function pendingCount()
  local n = #db.tombstones
  for _, item in db.items do
    if item.dirty then
      n += 1
    end
  end
  return n
end

local function publish()
  -- Newest first; done items after open ones, most recently completed first.
  -- Timestamps have 1s resolution, so ties fall back to insertion order. The
  -- order lives in plain string keys so table.sort needs no Lua comparator.
  local openKeys, doneKeys, byKey = {}, {}, {}
  for index, item in db.items do
    local stamp = (if item.done then item.completed else item.created) or ""
    local key = stamp .. string.format("|%08d", index)
    byKey[key] = item
    table.insert(if item.done then doneKeys else openKeys, key)
  end
  table.sort(openKeys)
  table.sort(doneKeys)
  local items = {}
  for _, keys in { openKeys, doneKeys } do
    for i = #keys, 1, -1 do
      local item = byKey[keys[i]]
      table.insert(items, { uid = item.uid, summary = item.summary, done = item.done })
    end
  end
  noctalia.state.set(SNAPSHOT_KEY, {
    items = items,
    openCount = #openKeys,
    status = status,
    error = errorText,
    pending = pendingCount(),
    lastSync = lastSync,
  })
end

-- ── configuration ───────────────────────────────────────────────────────────

-- Returns the connection settings, or nil plus a translation key.
local function connection()
  local host = trim(noctalia.getConfig("host"))
  local username = trim(noctalia.getConfig("username"))
  local password = noctalia.getConfig("password") or ""
  local passwordFile = trim(noctalia.getConfig("password_file"))
  if passwordFile ~= "" then
    local raw = noctalia.readFile(noctalia.expandPath(passwordFile))
    if raw == nil then
      return nil, "error.password_file"
    end
    password = raw:gsub("[\r\n]+$", "")
  end
  if host == "" or username == "" or password == "" then
    return nil, nil
  end
  if caldav.origin(host) == nil then
    return nil, "error.bad_host"
  end
  return {
    host = host,
    username = username,
    password = password,
    calendar = trim(noctalia.getConfig("calendar")),
  }
end

local function accountKey(conn)
  return conn.host .. "|" .. conn.username .. "|" .. conn.calendar
end

-- A different server/user/calendar invalidates everything synced from the old
-- one. Items created locally and never pushed are kept and go to the new one.
local function switchAccount(key)
  local kept = {}
  for _, item in db.items do
    if item.new then
      item.href = nil
      table.insert(kept, item)
    end
  end
  db.items = kept
  db.tombstones = {}
  db.account = key
  db.calendarUrl = ""
end

-- ── HTTP ────────────────────────────────────────────────────────────────────

local function request(conn, method, url, body, headers, cb)
  local accepted = noctalia.http({
    url = url,
    method = method,
    body = body or "",
    headers = headers or {},
    basic_username = conn.username,
    basic_password = conn.password,
  }, cb)
  if not accepted then
    cb({ ok = false, status = 0, body = "" })
  end
end

local function xmlHeaders(depth)
  return { "Content-Type: application/xml; charset=utf-8", "Depth: " .. depth }
end

local function isSuccess(res)
  return res.ok and res.status >= 200 and res.status < 300
end

-- ── sync ────────────────────────────────────────────────────────────────────

local sync -- forward declaration

local function scheduleNext()
  local interval = math.max(30, tonumber(noctalia.getConfig("sync_interval")) or 300)
  if status == "offline" then
    interval = math.min(interval, OFFLINE_RETRY_SECONDS)
  end
  nextSyncAt = os.time() + interval
end

local function finish(newStatus, err)
  syncing = false
  status = newStatus
  errorText = err or ""
  if newStatus == "ok" then
    lastSync = os.time()
  end
  if newStatus == "error" then
    noctalia.log("sync failed: " .. errorText)
  end
  scheduleNext()
  save()
  publish()
  if again then
    again = false
    sync()
  end
end

-- Maps a failed response to finish(); `what` names the failing step.
local function fail(res, what)
  if not res.ok then
    finish("offline", tr("status.offline_detail"))
  elseif res.status == 401 or (res.status == 403 and what == "discover") then
    finish("error", tr("error.auth"))
  else
    finish("error", tr("error.http", { what = what, status = res.status }))
  end
end

local function findItem(uid)
  for index, item in db.items do
    if item.uid == uid then
      return item, index
    end
  end
  return nil, nil
end

local function discover(conn, done)
  local candidates = caldav.endpointCandidates(conn.host)

  local function listCalendars(homeUrl)
    request(conn, "PROPFIND", homeUrl, caldav.CALENDARS_BODY, xmlHeaders(1), function(res)
      if not isSuccess(res) then
        return fail(res, "discover")
      end
      local cal, errKey = caldav.pickCalendar(caldav.parseCalendars(res.body, homeUrl), conn.calendar)
      if cal == nil then
        return finish("error", tr("error." .. errKey, { name = conn.calendar }))
      end
      db.calendarUrl = cal.url
      done()
    end)
  end

  local function findHome(principalUrl)
    request(conn, "PROPFIND", principalUrl, caldav.HOME_SET_BODY, xmlHeaders(0), function(res)
      local href = isSuccess(res) and caldav.hrefProperty(res.body, "calendar-home-set") or nil
      if href == nil then
        return if isSuccess(res) then finish("error", tr("error.no_home")) else fail(res, "discover")
      end
      listCalendars(caldav.withTrailingSlash(caldav.resolve(principalUrl, href)))
    end)
  end

  local function tryEndpoint(index)
    local url = candidates[index]
    if url == nil then
      return finish("error", tr("error.no_endpoint"))
    end
    request(conn, "PROPFIND", url, caldav.PRINCIPAL_BODY, xmlHeaders(0), function(res)
      if not res.ok or res.status == 401 then
        return fail(res, "discover")
      end
      local href = isSuccess(res) and caldav.hrefProperty(res.body, "current-user-principal") or nil
      if href == nil then
        return tryEndpoint(index + 1)
      end
      findHome(caldav.resolve(url, href))
    end)
  end

  tryEndpoint(1)
end

local function push(conn, done)
  local tombstones = table.clone(db.tombstones)
  local dirty = {}
  for _, item in db.items do
    if item.dirty then
      table.insert(dirty, item.uid)
    end
  end

  local pushItem -- forward declaration

  local function deleteNext(index)
    local tomb = tombstones[index]
    if tomb == nil then
      return pushItem(1)
    end
    request(conn, "DELETE", caldav.resolve(db.calendarUrl, tomb.href), nil, nil, function(res)
      if not (isSuccess(res) or res.ok and (res.status == 404 or res.status == 410)) then
        return fail(res, "delete")
      end
      for i, t in db.tombstones do
        if t.href == tomb.href then
          table.remove(db.tombstones, i)
          break
        end
      end
      deleteNext(index + 1)
    end)
  end

  function pushItem(index)
    local uid = dirty[index]
    if uid == nil then
      return done()
    end
    local item = findItem(uid)
    if item == nil or not item.dirty then
      return pushItem(index + 1) -- deleted or already pushed meanwhile
    end
    if item.href == nil then
      item.href = caldav.path(db.calendarUrl) .. uid .. ".ics"
    end
    local rev = item.rev
    local headers = { "Content-Type: text/calendar; charset=utf-8" }
    request(conn, "PUT", caldav.resolve(db.calendarUrl, item.href), item.ics, headers, function(res)
      if not isSuccess(res) then
        if res.ok and (res.status == 403 or res.status == 415) then
          return finish("error", tr("error.rejected"))
        end
        return fail(res, "upload")
      end
      local current = findItem(uid)
      if current ~= nil then
        current.new = false -- on the server now, so deleting it needs a tombstone
        current.etag = "" -- unknown until the next pull
        -- edited again while the upload was in flight: keep it queued
        current.dirty = current.rev ~= rev
      end
      pushItem(index + 1)
    end)
  end

  deleteNext(1)
end

local function pull(conn, done)
  local merge -- forward declaration: runs once the etag list is parsed

  request(conn, "REPORT", db.calendarUrl, caldav.ETAGS_BODY, xmlHeaders(1), function(res)
    if not isSuccess(res) then
      if res.ok and res.status == 404 then
        db.calendarUrl = "" -- calendar is gone, rediscover next time
      end
      return fail(res, "list")
    end
    local body = res.body
    local remote = {}
    local pos = 1
    local function parseSlice()
      for _ = 1, RESPONSES_PER_SLICE do
        local response, nextPos = xml.nextResponse(body, pos)
        if response == nil then
          return true
        end
        pos = nextPos
        local entry = caldav.etagOf(response)
        if entry ~= nil then
          remote[caldav.normalize(entry.href)] = entry
        end
      end
      return false
    end

    local function step()
      if parseSlice() then
        merge(remote)
      else
        defer(step)
      end
    end

    step()
  end)

  function merge(remote)
    local deleting = {}
    for _, tomb in db.tombstones do
      deleting[caldav.normalize(tomb.href)] = true
    end

    -- drop synced items that are gone from the server
    local local_ = {}
    for i = #db.items, 1, -1 do
      local item = db.items[i]
      if item.href ~= nil then
        local key = caldav.normalize(item.href)
        if remote[key] == nil and not item.dirty and not item.new then
          table.remove(db.items, i)
        else
          local_[key] = item
        end
      end
    end

    local toFetch = {}
    for key, entry in remote do
      local item = local_[key]
      if not deleting[key] and (item == nil or (not item.dirty and item.etag ~= entry.etag)) then
        table.insert(toFetch, entry.href)
      end
    end

    local function fetchBatch(start)
      if start > #toFetch then
        return done()
      end
      local hrefs = table.move(toFetch, start, math.min(start + MULTIGET_BATCH - 1, #toFetch), 1, {})
      request(conn, "REPORT", db.calendarUrl, caldav.multigetBody(hrefs), xmlHeaders(1), function(batch)
        if not isSuccess(batch) then
          return fail(batch, "fetch")
        end
        for _, object in caldav.parseObjects(batch.body) do
          local todo = ical.parse(object.ics)
          local key = caldav.normalize(object.href)
          local item = local_[key]
          if todo ~= nil and not (item ~= nil and item.dirty) and not deleting[key] then
            if item == nil then
              item = { href = object.href, rev = 0, dirty = false, new = false }
              local_[key] = item
              table.insert(db.items, item)
            end
            item.uid = todo.uid or object.href
            item.etag = object.etag
            item.ics = object.ics
            item.summary = todo.summary
            item.done = todo.done
            item.created = todo.created
            item.completed = todo.completed
          end
        end
        fetchBatch(start + MULTIGET_BATCH)
      end)
    end

    fetchBatch(1)
  end
end

function sync()
  if syncing then
    again = true
    return
  end
  local conn, errKey = connection()
  if conn == nil then
    status = errKey and "error" or "unconfigured"
    errorText = errKey and tr(errKey) or ""
    scheduleNext()
    publish()
    return
  end
  local key = accountKey(conn)
  if db.account ~= key then
    switchAccount(key)
  end
  syncing = true
  status = "syncing"
  publish()

  local function run()
    push(conn, function()
      pull(conn, function()
        finish("ok")
      end)
    end)
  end

  if db.calendarUrl == "" then
    discover(conn, run)
  else
    run()
  end
end

-- ── local edits ─────────────────────────────────────────────────────────────

local function newUid()
  local parts = {}
  for _, len in { 8, 4, 4, 4, 12 } do
    local chunk = {}
    for _ = 1, len do
      table.insert(chunk, string.format("%x", math.random(0, 15)))
    end
    table.insert(parts, table.concat(chunk))
  end
  return table.concat(parts, "-")
end

local function changed()
  save()
  publish()
  sync()
end

local function addTodo(text)
  local summary = trim(text):gsub("%s+", " ")
  if summary == "" then
    return
  end
  local uid = newUid()
  local now = ical.utcNow()
  table.insert(db.items, {
    uid = uid,
    ics = ical.create(uid, summary, now),
    etag = "",
    summary = summary,
    done = false,
    created = now,
    completed = "",
    dirty = true,
    new = true,
    rev = 1,
  })
  changed()
end

local function toggleTodo(uid)
  local item = findItem(uid)
  if item == nil then
    return
  end
  local now = ical.utcNow()
  item.done = not item.done
  item.completed = item.done and now or ""
  item.ics = ical.setDone(item.ics, item.done, now)
  item.dirty = true
  item.rev += 1
  changed()
end

local function deleteTodo(uid)
  local item, index = findItem(uid)
  if item == nil then
    return
  end
  table.remove(db.items, index)
  if not item.new and item.href ~= nil then
    table.insert(db.tombstones, { href = item.href })
  end
  changed()
end

-- ── wiring ──────────────────────────────────────────────────────────────────

noctalia.state.watch(CMD_KEY, function(cmd)
  if type(cmd) ~= "table" then
    return
  end
  if cmd.action == "add" then
    addTodo(cmd.text)
  elseif cmd.action == "toggle" then
    toggleTodo(cmd.uid)
  elseif cmd.action == "delete" then
    deleteTodo(cmd.uid)
  elseif cmd.action == "sync" then
    sync()
  end
end)

function onIpc(event, payload)
  if event == "add" then
    addTodo(payload or "")
  elseif event == "sync" then
    sync()
  end
end

-- sync() itself resets the cache when server, user or calendar changed
function onConfigChanged()
  sync()
end

function update()
  if not syncing and os.time() >= nextSyncAt then
    sync()
  end
end

math.randomseed(noctalia.nowMs() % 2147483647)
load()
publish()
noctalia.setUpdateInterval(5000)
sync()
