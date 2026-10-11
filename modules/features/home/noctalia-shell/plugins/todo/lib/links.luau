--!nonstrict
-- URL detection in todo text. Summaries are short, so plain Lua patterns are
-- cheap enough here even under noctalia's CPU-budget hook.

local M = {}

-- Characters that end a sentence rather than a URL.
local TRAILING = { ["."] = true, [","] = true, [";"] = true, [":"] = true, ["!"] = true, ["?"] = true, ["'"] = true }
local CLOSING = { [")"] = "(", ["]"] = "[", ["}"] = "{" }

local function count(s, char)
  local n = 0
  local pos = s:find(char, 1, true)
  while pos ~= nil do
    n += 1
    pos = s:find(char, pos + 1, true)
  end
  return n
end

-- Drops trailing punctuation, and closing brackets that have no opening
-- partner inside the URL: "(see https://x.org/a_(b))." -> "https://x.org/a_(b)".
local function trimTail(url)
  while #url > 0 do
    local last = url:sub(-1)
    local opening = CLOSING[last]
    if TRAILING[last] or (opening ~= nil and count(url, opening) < count(url, last)) then
      url = url:sub(1, -2)
    else
      break
    end
  end
  return url
end

-- Distinct http(s) URLs in order of appearance.
function M.extract(text)
  local urls, seen = {}, {}
  if text == nil or text:lower():find("http", 1, true) == nil then
    return urls
  end
  for raw in text:gmatch("[hH][tT][tT][pP][sS]?://[^%s<>\"]+") do
    local url = trimTail(raw)
    -- something must follow the scheme
    if url:find("://.", 1) ~= nil and not seen[url] then
      seen[url] = true
      table.insert(urls, url)
    end
  end
  return urls
end

-- Compact label: no scheme, no trailing slash, at most `max` characters.
function M.shorten(url, max)
  local short = url:gsub("^[hH][tT][tT][pP][sS]?://", ""):gsub("/$", "")
  max = max or 60
  if utf8.len(short) ~= nil and utf8.len(short) > max then
    short = short:sub(1, utf8.offset(short, max) - 1) .. "…"
  end
  return short
end

return M
