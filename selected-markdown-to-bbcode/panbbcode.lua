-- panbbcode - BBCode writer for pandoc
-- Copyright (C) 2014 Jens Oliver John < dev ! 2ion ! de >
-- Licensed under the GNU General Public License v3 or later.
-- Written for Lua 5.{1,2}

-- PRIVATE

local function enclose(t, s, p)
  if p then
    return string.format("[%s=%s]%s[/%s]", t, p, s, t)
  else
    return string.format("[%s]%s[/%s]", t, s, t)
  end
end

local function lookup(t, e)
  for _,v in ipairs(t) do
    if v == e then
        return true
    end
  end
  return false
end

local strlen_ger_utf8_t = { [0xc3] = { 0xa4, 0x84, 0xbc, 0x9c, 0xb6, 0x96, 0x9f } }

-- FIXME: check also the byte *after* occurences of 0xc3 (and keep the
-- loop for that)
local function strlen_ger_utf8(w)
  local s = {}
  local len = 0
  w:gsub("(.)", function (c)
    table.insert(s, c:byte())
  end)
  for i=1,#s do
    if strlen_ger_utf8_t[s[i]] then
      i = i + 1
    else
      len = len + 1
    end
  end
  return len
end

local function column(s, sep, blind)
  local s = s
  local sep = sep or "   "
  local blind = blind or ""
  local ret = ""

  local y = {}
  local x = {}
  local cm = 0
  local i = 0

  for line in s:gmatch("[^\r\n]+") do
    local ly = {}
    local cc = 0
    line:gsub("[^@]+", function (m)
      local len = #m
      cc = cc + 1
      if cc > cm then 
        x[cc] = 0
        cm = cc
      end
      if len > x[cc] then
        x[cc] = len
      end
      table.insert(ly, m)
    end)
    table.insert(y, ly)
  end
  for _,line in ipairs(y) do
    for tmp=1,(#x-#line) do
        table.insert(line, blind)
    end
    for i,word in ipairs(line) do
      -- workaround for common German utf-8 umlauts
      local wl = word:match("[öäüÖÄÜß]") and strlen_ger_utf8(word) or #word
      if wl < x[i] then
        for tmp=1,(x[i]-wl) do
          word = word .. " "
        end
      end
     ret = ret .. word .. sep
    end
    ret = ret .. '\n'
  end
  return ret
end

-- PUBLIC

local cache_notes = {}

function Doc( body, meta, vars )
  local buf = {}
  local function _(e)
    table.insert(buf, e)
  end
  if meta['title'] and meta['title'] ~= "" then
    _(meta['title'])
  end
  _(body)
  if #cache_notes > 0 then
    _("--")
    for i,n in ipairs(cache_notes) do
      _(string.format("[%d] %s", i, n))
    end
  end
  return table.concat(buf, '\n')
end

function Str(s)
  return s
end

function Space()
  return ' '
end

function LineBreak()
  return '\n'
end

function Emph(s)
  return enclose('em', s)
end

function Strong(s)
  return enclose('b', s)
end

function Subscript(s)
  return string.format("{%s}", s)
end

function Superscript(s)
  return string.format("[%s]", s)
end

function SmallCaps(s)
  return s
end

function Strikeout(s)
  return enclose('s', s)
end

function Link(s, src, title)
  return enclose('url', s, src)
end

function Image(s, src, title)
  return enclose('img', s, src)
end

function CaptionedImage(src, attr, title)
  if not title or title == "" then
    return enclose('img', src)
  else
    return enclose('img', src, title)
  end
end

function Code(s, attr)
  return string.format("[code]%s[/code]", s)
end

function InlineMath(s)
  return s
end

function DisplayMath(s)
  return s
end

function Note(s)
  table.insert(cache_notes, s)
  return string.format("[%d]", #cache_notes)
end

function Span(s, attr)
  return s
end

function Plain(s)
  return s
end

function Para(s)
  return s
end

function Header(level, s, attr)
  if level == 1 then
    return enclose('h', s)
  elseif level == 2 then
    return enclose('b', enclose('u', s))
  else
    return enclose('b', s)
  end
end

function BlockQuote(s)
  local a, t = s:match('@([%w]+): (.+)')
  if a then
    return enclose('quote', t or "Unknown" , a)
  else
    return enclose('quote', s)
  end
end

function Cite(s)
  return s
end

function Blocksep(s)
  return "\n\n"
end

function HorizontalRule(s)
  return '--'
end

function CodeBlock(s, attr)
  return enclose('code', s)
end

local function makelist(items, ltype)
  local buf = string.format("[list=%s]", ltype)
  for _,e in ipairs(items) do
    buf = buf .. enclose('*', e) .. '\n'
  end
  buf = buf .. '[/list]'
  return buf
end

function BulletList(items)
  return makelist(items, '*')
end

function OrderedList(items)
  return makelist(items, '1')
end

function DefinitionList(items)
  local buf = ""
  local function mkdef(k,v)
    return string.format("%s: %s\n", enclose('b', k), v)
  end
  for _,e in ipairs(items) do
    for k,v in pairs(items) do
      buf = buf .. mkdef(k,v)
    end
  end
  return buf
end

function html_align(align)
  return ""
end

function Table(cap, align, widths, headers, rows)
  local buf = {}
  for _,r in ipairs(rows) do
    local rbuf = ""
    for i,c in ipairs(r) do
      if i~=#r then
        rbuf = rbuf .. c .. '@'
      else
        rbuf = rbuf .. c
      end
    end
    table.insert(buf, rbuf)
  end
  local cin = table.concat(buf, '\n')
  return enclose('code', column(cin))
end

function Div(s, attr)
  return s
end

-- boilerplate

local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)
