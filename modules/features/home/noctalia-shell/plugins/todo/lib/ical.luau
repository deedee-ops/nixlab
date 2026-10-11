--!nonstrict
-- Just enough iCalendar (RFC 5545) for VTODO quick-add lists: read UID/SUMMARY/
-- status, create a new VTODO, and flip a VTODO between done and not done.
-- Existing objects are edited in place, so properties set by other clients
-- (DUE, PRIORITY, alarms, ...) survive a round trip through this plugin.

local M = {}

local PRODID = "-//ajgon//noctalia todo//EN"
-- Properties rewritten when the completion state changes.
local STATE_PROPS = {
  ["STATUS"] = true,
  ["COMPLETED"] = true,
  ["PERCENT-COMPLETE"] = true,
  ["LAST-MODIFIED"] = true,
  ["DTSTAMP"] = true,
}

export type Todo = {
  uid: string?,
  summary: string,
  done: boolean,
  created: string,
  completed: string,
}

-- Plain find/sub only: noctalia's CPU-budget hook makes Lua pattern matching
-- very expensive (see xml.luau), and this runs for every downloaded todo.

-- Unfolds continuation lines and splits into logical lines (CRLF or LF).
local function unfold(text: string): { string }
  local lines = {}
  local pos = 1
  local len = #text
  while pos <= len do
    local nl = text:find("\n", pos, true) or len + 1
    local line = text:sub(pos, nl - 1)
    if line:sub(-1) == "\r" then
      line = line:sub(1, -2)
    end
    local first = line:sub(1, 1)
    if (first == " " or first == "\t") and #lines > 0 then
      lines[#lines] ..= line:sub(2)
    elseif line ~= "" then
      table.insert(lines, line)
    end
    pos = nl + 1
  end
  return lines
end

-- Splits a content line into upper-cased name, raw params and value. The
-- name/value separator is the first ':' outside a quoted parameter value.
local function splitLine(line: string): (string, string, string)
  local colon = line:find(":", 1, true)
  if colon == nil then
    return line:upper(), "", ""
  end
  local quote = line:find('"', 1, true)
  if quote ~= nil and quote < colon then
    -- quoted parameter values may contain ':'; walk past them
    local pos = quote
    while true do
      local closeQuote = line:find('"', pos + 1, true)
      if closeQuote == nil then
        return line:upper(), "", ""
      end
      colon = line:find(":", closeQuote + 1, true)
      local nextQuote = line:find('"', closeQuote + 1, true)
      if colon == nil then
        return line:upper(), "", ""
      end
      if nextQuote == nil or nextQuote > colon then
        break
      end
      pos = nextQuote
    end
  end
  local head = line:sub(1, colon - 1)
  local semi = head:find(";", 1, true)
  local name = if semi then head:sub(1, semi - 1) else head
  local params = if semi then head:sub(semi) else ""
  return name:upper(), params, line:sub(colon + 1)
end

local UNESCAPE = { n = "\n", N = "\n" }

function M.unescape(value: string): string
  local slash = value:find("\\", 1, true)
  if slash == nil then
    return value
  end
  local out = {}
  local pos = 1
  while slash ~= nil do
    table.insert(out, value:sub(pos, slash - 1))
    local c = value:sub(slash + 1, slash + 1)
    table.insert(out, UNESCAPE[c] or c)
    pos = slash + 2
    slash = value:find("\\", pos, true)
  end
  table.insert(out, value:sub(pos))
  return table.concat(out)
end

-- Only used on short user input, so patterns are fine here.
function M.escape(value: string): string
  return (value:gsub("\\", "\\\\"):gsub(";", "\\;"):gsub(",", "\\,"):gsub("\r?\n", "\\n"))
end

-- Folds a content line at 75 octets without splitting UTF-8 sequences.
local function fold(line: string): string
  if #line <= 75 then
    return line
  end
  local parts = {}
  local start = 1
  local limit = 75
  while #line - start + 1 > limit do
    local cut = start + limit
    -- never start a continuation on a UTF-8 continuation byte (10xxxxxx)
    while cut > start + 1 do
      local byte = line:byte(cut)
      if byte == nil or byte < 0x80 or byte >= 0xC0 then
        break
      end
      cut -= 1
    end
    table.insert(parts, line:sub(start, cut - 1))
    start = cut
    limit = 74 -- continuation lines spend one octet on the leading space
  end
  table.insert(parts, line:sub(start))
  return table.concat(parts, "\r\n ")
end

local function serialize(lines: { string }): string
  local out = table.create(#lines)
  for i, line in lines do
    out[i] = fold(line)
  end
  return table.concat(out, "\r\n") .. "\r\n"
end

function M.utcNow(): string
  return os.date("!%Y%m%dT%H%M%SZ") :: string
end

-- Reads the first VTODO of a calendar object. Returns nil when there is none.
function M.parse(ics: string): Todo?
  local stack = {}
  local todo: Todo? = nil
  local status = ""
  for _, line in unfold(ics) do
    local name, _, value = splitLine(line)
    if name == "BEGIN" then
      table.insert(stack, value:upper())
      if value:upper() == "VTODO" and todo == nil then
        todo = { summary = "", done = false, created = "", completed = "" }
      end
    elseif name == "END" then
      local closed = table.remove(stack)
      if closed == "VTODO" and todo ~= nil then
        break
      end
    elseif todo ~= nil and stack[#stack] == "VTODO" then
      if name == "UID" then
        todo.uid = value
      elseif name == "SUMMARY" then
        todo.summary = M.unescape(value)
      elseif name == "STATUS" then
        status = value:upper()
      elseif name == "COMPLETED" then
        todo.completed = value
      elseif name == "CREATED" or (name == "DTSTAMP" and todo.created == "") then
        todo.created = value
      end
    end
  end
  if todo ~= nil then
    todo.done = status == "COMPLETED" or status == "CANCELLED" or (status == "" and todo.completed ~= "")
  end
  return todo
end

function M.create(uid: string, summary: string, now: string): string
  return serialize({
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:" .. PRODID,
    "BEGIN:VTODO",
    "UID:" .. uid,
    "DTSTAMP:" .. now,
    "CREATED:" .. now,
    "LAST-MODIFIED:" .. now,
    "SUMMARY:" .. M.escape(summary),
    "STATUS:NEEDS-ACTION",
    "END:VTODO",
    "END:VCALENDAR",
  })
end

-- Rewrites the completion state of every VTODO in the object, keeping all
-- other properties and components (e.g. VALARM, VTIMEZONE) untouched.
-- DTSTAMP gets rewritten, so a VTODO without CREATED gets one from the old
-- DTSTAMP: the list is ordered by creation time, which must not move.
function M.setDone(ics: string, done: boolean, now: string): string
  local out = {}
  local stack = {}
  local created, stamp = false, nil
  for _, line in unfold(ics) do
    local name, _, value = splitLine(line)
    local inTodo = stack[#stack] == "VTODO"
    if inTodo and name == "CREATED" then
      created = true
    elseif inTodo and name == "DTSTAMP" then
      stamp = value
    end
    if name == "BEGIN" then
      table.insert(stack, value:upper())
      if value:upper() == "VTODO" then
        created, stamp = false, nil
      end
      table.insert(out, line)
    elseif name == "END" then
      if value:upper() == "VTODO" and inTodo then
        if not created and stamp ~= nil then
          table.insert(out, "CREATED:" .. stamp)
        end
        table.insert(out, "DTSTAMP:" .. now)
        table.insert(out, "LAST-MODIFIED:" .. now)
        if done then
          table.insert(out, "STATUS:COMPLETED")
          table.insert(out, "COMPLETED:" .. now)
          table.insert(out, "PERCENT-COMPLETE:100")
        else
          table.insert(out, "STATUS:NEEDS-ACTION")
        end
      end
      table.remove(stack)
      table.insert(out, line)
    elseif not (inTodo and STATE_PROPS[name]) then
      table.insert(out, line)
    end
  end
  return serialize(out)
end

return M
