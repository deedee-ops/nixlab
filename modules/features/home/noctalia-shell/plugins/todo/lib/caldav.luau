--!nonstrict
-- CalDAV request bodies, URL handling and multistatus parsing. Pure functions
-- only; the service owns the HTTP calls and the sync state machine.

local xml = require("./xml.luau")

local M = {}

local XML_HEAD = '<?xml version="1.0" encoding="utf-8"?>'
local NS = 'xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"'

export type Calendar = { url: string, name: string, todos: boolean }
export type Etag = { href: string, etag: string }
export type Object = { href: string, etag: string, ics: string }

M.PRINCIPAL_BODY = XML_HEAD
  .. "<d:propfind " .. NS .. "><d:prop><d:current-user-principal/></d:prop></d:propfind>"

M.HOME_SET_BODY = XML_HEAD
  .. "<d:propfind " .. NS .. "><d:prop><c:calendar-home-set/></d:prop></d:propfind>"

M.CALENDARS_BODY = XML_HEAD
  .. "<d:propfind " .. NS .. "><d:prop>"
  .. "<d:resourcetype/><d:displayname/><c:supported-calendar-component-set/>"
  .. "</d:prop></d:propfind>"

M.ETAGS_BODY = XML_HEAD
  .. "<c:calendar-query " .. NS .. "><d:prop><d:getetag/></d:prop>"
  .. '<c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VTODO"/></c:comp-filter></c:filter>'
  .. "</c:calendar-query>"

function M.multigetBody(hrefs: { string }): string
  local parts = {
    XML_HEAD,
    "<c:calendar-multiget " .. NS .. "><d:prop><d:getetag/><c:calendar-data/></d:prop>",
  }
  for _, href in hrefs do
    table.insert(parts, "<d:href>" .. xml.escape(href) .. "</d:href>")
  end
  table.insert(parts, "</c:calendar-multiget>")
  return table.concat(parts)
end

-- "https://host:port" part of a URL, or nil.
function M.origin(url: string): string?
  return url:match("^(https?://[^/]+)")
end

-- Path part of a URL ("/" when there is none).
function M.path(url: string): string
  local path = url:match("^https?://[^/]+(/.*)$")
  return path or "/"
end

function M.withTrailingSlash(url: string): string
  return if url:sub(-1) == "/" then url else url .. "/"
end

-- Resolves an href from a response against the URL it was requested from.
function M.resolve(base: string, href: string): string
  if href:match("^https?://") then
    return href
  end
  if href:sub(1, 1) == "/" then
    return (M.origin(base) or "") .. href
  end
  return (base:match("^(.*/)") or base) .. href
end

-- Comparable form of an href: path only, percent-decoded. Hot path (once per
-- todo per sync), so patterns only run when there is something to rewrite.
function M.normalize(href: string): string
  local path = if href:sub(1, 4) == "http" then M.path(href) else href
  if path:find("%", 1, true) == nil then
    return path
  end
  return (path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16) :: number)
  end))
end

-- Collections that may host the CalDAV principal, most specific first.
function M.endpointCandidates(host: string): { string }
  local origin = M.origin(host)
  if origin == nil then
    return {}
  end
  local path = M.path(host)
  if path ~= "/" then
    return { M.withTrailingSlash(host) }
  end
  return { origin .. "/dav/", origin .. "/remote.php/dav/", origin .. "/dav.php/", origin .. "/" }
end

-- href inside the named property of the first response that has it.
function M.hrefProperty(body: string, property: string): string?
  for _, response in xml.elements(body, "response") do
    local href = xml.firstText(xml.first(xml.okProps(response), property), "href")
    if href ~= nil and href ~= "" then
      return href
    end
  end
  return nil
end

function M.parseCalendars(body: string, base: string): { Calendar }
  local out = {}
  for _, response in xml.elements(body, "response") do
    local href = xml.firstText(response, "href")
    local props = xml.okProps(response)
    local resourcetype = xml.first(props, "resourcetype") or ""
    if href ~= nil and #xml.elements(resourcetype, "calendar") > 0 then
      -- servers may omit the set, which means every component is allowed;
      -- <comp name="VTODO"/> is self-closing, so look at the raw markup
      local components = xml.first(props, "supported-calendar-component-set")
      local todos = components == nil
        or components:find('"VTODO"', 1, true) ~= nil
        or components:find("'VTODO'", 1, true) ~= nil
      local name = xml.firstText(props, "displayname") or ""
      table.insert(out, { url = M.withTrailingSlash(M.resolve(base, href)), name = name, todos = todos })
    end
  end
  return out
end

-- Picks the calendar named `wanted` (display name or last path segment,
-- case-insensitive), or the first one accepting VTODOs when `wanted` is empty.
function M.pickCalendar(calendars: { Calendar }, wanted: string): (Calendar?, string?)
  local needle = wanted:lower()
  for _, cal in calendars do
    if needle == "" then
      if cal.todos then
        return cal, nil
      end
    else
      local segment = M.normalize(M.path(cal.url)):match("([^/]+)/?$") or ""
      if cal.name:lower() == needle or segment:lower() == needle then
        if not cal.todos then
          return nil, "calendar_no_todos"
        end
        return cal, nil
      end
    end
  end
  return nil, if needle == "" then "no_todo_calendar" else "calendar_not_found"
end

-- A property listed in a 404 propstat is self-closing, so an empty value
-- means "missing"; that avoids walking the propstats on the hot path.
function M.etagOf(response: string): Etag?
  local href = xml.firstText(response, "href")
  local etag = xml.firstText(response, "getetag")
  if href == nil or etag == nil or etag == "" then
    return nil
  end
  return { href = href, etag = etag }
end

function M.objectOf(response: string): Object?
  local href = xml.firstText(response, "href")
  local data = xml.first(response, "calendar-data")
  if href == nil or data == nil or data == "" then
    return nil
  end
  return { href = href, etag = xml.firstText(response, "getetag") or "", ics = xml.text(data) }
end

local function collect(body: string, parse)
  local out = {}
  local pos = 1
  while true do
    local response, nextPos = xml.nextResponse(body, pos)
    if response == nil then
      return out
    end
    local value = parse(response)
    if value ~= nil then
      table.insert(out, value)
    end
    pos = nextPos
  end
end

function M.parseEtags(body: string): { Etag }
  return collect(body, M.etagOf)
end

function M.parseObjects(body: string): { Object }
  return collect(body, M.objectOf)
end

return M
