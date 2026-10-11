--!nonstrict
-- Minimal, namespace-prefix-agnostic WebDAV XML helpers. Servers pick their own
-- prefixes (sabre/dav uses `d:`/`cal:`, Radicale none, others `D:`/`C:`), so
-- elements are matched by local name only. Good enough for multistatus
-- responses; not a general XML parser.
--
-- Performance matters more than elegance here: noctalia meters every callback
-- with an interrupt hook that also fires inside Lua pattern matching, which
-- makes gsub/gmatch/pattern-find on response bodies ~50x slower than plain
-- string.find + sub. So everything below scans with plain finds only.

local M = {}

local ENTITIES = {
  ["&amp;"] = "&",
  ["&lt;"] = "<",
  ["&gt;"] = ">",
  ["&quot;"] = '"',
  ["&apos;"] = "'",
  ["&#13;"] = "\r",
  ["&#10;"] = "\n",
  ["&#9;"] = "\t",
  ["&#xD;"] = "\r",
  ["&#xA;"] = "\n",
  ["&#x9;"] = "\t",
  ["&#xd;"] = "\r",
  ["&#xa;"] = "\n",
  ["&#34;"] = '"',
  ["&#39;"] = "'",
}

local function decodeEntity(entity)
  local known = ENTITIES[entity]
  if known ~= nil then
    return known
  end
  -- rare numeric references; short string, so a pattern is fine here
  local hex = entity:match("^&#[xX](%x+);$")
  local dec = entity:match("^&#(%d+);$")
  local code = if hex then tonumber(hex, 16) elseif dec then tonumber(dec) else nil
  return if code then utf8.char(code) else entity
end

local function decodeEntities(s)
  local amp = s:find("&", 1, true)
  if amp == nil then
    return s
  end
  local out = {}
  local pos = 1
  while amp ~= nil do
    local semi = s:find(";", amp, true)
    if semi == nil or semi - amp > 10 then
      table.insert(out, s:sub(pos, amp))
      pos = amp + 1
    else
      table.insert(out, s:sub(pos, amp - 1))
      table.insert(out, decodeEntity(s:sub(amp, semi)))
      pos = semi + 1
    end
    amp = s:find("&", pos, true)
  end
  table.insert(out, s:sub(pos))
  return table.concat(out)
end

-- Text content of a fragment: CDATA sections verbatim, entities decoded elsewhere.
function M.text(s)
  if s == nil then
    return ""
  end
  if s:find("<![CDATA[", 1, true) == nil then
    return decodeEntities(s)
  end
  local out = {}
  local pos = 1
  while true do
    local a, b = s:find("<![CDATA[", pos, true)
    if a == nil then
      table.insert(out, decodeEntities(s:sub(pos)))
      break
    end
    table.insert(out, decodeEntities(s:sub(pos, a - 1)))
    local c, d = s:find("]]>", b + 1, true)
    if c == nil then
      table.insert(out, s:sub(b + 1))
      break
    end
    table.insert(out, s:sub(b + 1, c - 1))
    pos = d + 1
  end
  return table.concat(out)
end

local TAG_END = { [">"] = true, ["/"] = true, [" "] = true, ["\t"] = true, ["\r"] = true, ["\n"] = true }

-- Finds the next start tag with local name `name` at or after `init`.
-- Returns tagStart, contentStart, qualifiedName, selfClosing.
local function openTag(s, name, init)
  local pos = init
  while true do
    local a = s:find(name, pos, true)
    if a == nil then
      return nil
    end
    local before = s:sub(a - 1, a - 1)
    local finish = a + #name
    if (before == ":" or before == "<") and TAG_END[s:sub(finish, finish)] then
      -- walk back over the (short) prefix to the '<'
      local lt = a - 1
      while lt > 0 and a - lt < 32 and s:sub(lt, lt) ~= "<" do
        lt -= 1
      end
      if s:sub(lt, lt) == "<" and s:sub(lt + 1, lt + 1) ~= "/" then
        local gt = s:find(">", finish, true)
        if gt == nil then
          return nil
        end
        return lt, gt + 1, s:sub(lt + 1, finish - 1), s:sub(gt - 1, gt - 1) == "/"
      end
    end
    pos = a + 1
  end
end

-- Inner contents of the elements whose local name is `name` (at most `limit`),
-- in document order. Self-closing elements yield "". Same-name nesting is not
-- supported.
function M.elements(s, name, limit)
  local out = {}
  local max = limit or math.huge
  local pos = 1
  while #out < max do
    local _, contentStart, qname, selfClosing = openTag(s, name, pos)
    if contentStart == nil then
      break
    end
    if selfClosing then
      table.insert(out, "")
      pos = contentStart
    else
      local closing = "</" .. qname .. ">"
      local endA = s:find(closing, contentStart, true)
      if endA == nil then
        break
      end
      table.insert(out, s:sub(contentStart, endA - 1))
      pos = endA + #closing
    end
  end
  return out
end

function M.first(s, name)
  if s == nil then
    return nil
  end
  return M.elements(s, name, 1)[1]
end

-- Iterator over <response> elements starting at byte `init`; yields
-- (response, nextPos) so callers can process a long multistatus in chunks.
function M.nextResponse(s, init)
  local _, contentStart, qname, selfClosing = openTag(s, "response", init)
  if contentStart == nil or selfClosing then
    return nil, nil
  end
  local closing = "</" .. qname .. ">"
  local endA = s:find(closing, contentStart, true)
  if endA == nil then
    return nil, nil
  end
  return s:sub(contentStart, endA - 1), endA + #closing
end

-- Concatenated <prop> contents of the propstats that answered 200, i.e. the
-- properties the server actually has (404 propstats list the missing ones).
function M.okProps(response)
  local out = {}
  for _, propstat in M.elements(response, "propstat") do
    local status = M.first(propstat, "status") or ""
    if status:find(" 200", 1, true) then
      table.insert(out, M.first(propstat, "prop") or "")
    end
  end
  return table.concat(out)
end

local WHITESPACE = { [" "] = true, ["\t"] = true, ["\r"] = true, ["\n"] = true }

local function trim(s)
  -- cheap common case: no surrounding whitespace
  if not WHITESPACE[s:sub(1, 1)] and not WHITESPACE[s:sub(-1)] then
    return s
  end
  return s:match("^%s*(.-)%s*$")
end

-- Text of the first `name` element, whitespace-trimmed.
function M.firstText(s, name)
  local inner = M.first(s, name)
  if inner == nil then
    return nil
  end
  return trim(M.text(inner))
end

function M.escape(s)
  if s:find("[&<>\"]") == nil then
    return s
  end
  return (s:gsub("[&<>\"]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }))
end

return M
