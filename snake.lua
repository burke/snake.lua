-- vim: foldmethod=marker

-- {{{ StoreMeta type --------------------------------------------------------
local StoreMeta = {
  __newindex = function(t, k, v)
    t.__dict:set(k, v)
  end,

  __index = function(t, k)
    return t.__dict:get(k)
  end
}
-- }}}

-- {{{ Board type ------------------------------------------------------------

local Board = {}

function Board:render()

  local str = ""
  for y=1, self.height do
    for x=1, self.width do
      local chr = '.'
      if x == self.store.apple_x and y == self.store.apple_y then
        chr = 'O'
      elseif self:visited(x, y) then
        if self.store.dead then
          chr = 'X'
        else
          chr = '#'
        end
      end
      str = str .. chr
    end
    str = str .. "\n"
  end
  return str
end

function Board:visited(x, y)
  if self.store.snakelist:find(";" .. x .. "," .. y .. ";", 0, true) then
    return true
  end
  return false
end

function Board:init(store, width, height)
  self.store = store
  self.width, self.height = width, height

  self.store.len       = self.store.len       or 0
  self.store.cap       = self.store.cap       or 8
  self.store.x         = self.store.x         or 1
  self.store.y         = self.store.y         or 1
  self.store.dead      = self.store.dead      or false

  sl = self.store.snakelist
  if sl == nil then
    self.store.snakelist = ';'
    self:appendtrim(self.store.x, self.store.y)
  end

  self:setapple()
end

function Board:eatapple()
  self.store.cap = self.store.cap + 1
  repeat
    self.store.apple_x = nil
    self.store.apple_y = nil
    self:setapple()
  until not self:visited(self.store.apple_x, self.store.apple_y)
end

function Board:setapple()
  self.store.apple_x = self.store.apple_x or math.random(self.width)
  self.store.apple_y = self.store.apple_y or math.random(self.height)
end

function Board:appendtrim(x, y)
  self.store.snakelist = self.store.snakelist .. x .. ',' .. y .. ';'
  self.store.len = self.store.len + 1

  if self.store.len > self.store.cap then
    self.store.len = self.store.len - 1
    local startpos = self.store.snakelist:find(";", 2, true)
    self.store.snakelist = self.store.snakelist:sub(startpos, -1)
  end
end

function Board:move(dir)
  if self.store.dead then
    return
  end

  local x, y = self.store.x, self.store.y

  if dir == "right" then
    x = x + 1
    if x > self.width then x = self.width end
  elseif dir == "left" then
    x = x - 1
    if x < 1 then x = 1 end
  elseif dir == "down" then
    y = y + 1
    if y > self.height then y = self.height end
  elseif dir == "up" then
    y = y - 1
    if y < 1 then y = 1 end
  else
    error("invalid direction")
  end

  self.store.x = x
  self.store.y = y

  if self:visited(x, y) then
    self.store.dead = true
  end

  self:appendtrim(x, y)

  if x == self.store.apple_x and y == self.store.apple_y then
    self:eatapple()
  end
end

function Board:dead()
  return self.store.dead
end

-- }}}

-- {{{ main ------------------------------------------------------------------
function main()

  local board  = setmetatable({}, {__index = Board})
  local width  = 12
  local height = 8

  local store = setmetatable({__dict = ngx.shared.snake}, StoreMeta)

  board:init(store, width, height)
  board:move(ngx.var.dir)

  if not board:dead() then
    ngx.header.refresh = '0.5'
  end

  ngx.say(
[[<!doctype HTML>
<html>
<body>
<pre>
]] .. board:render() .. [[
</pre>
<a href="/snake/left">left</a>
<a href="/snake/right">right</a>
<a href="/snake/up">up</a>
<a href="/snake/down">down</a>
</body>
</html>]]
  )

end
main()
-- }}}
