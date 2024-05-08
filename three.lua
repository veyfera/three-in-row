math.randomseed(os.time())

function newGame()
  self = {
    Y = 10,
    X = 10,
    colors = {'A', 'B', 'C', 'D', 'E', 'F'},
    directions = "lrud",
    f = {},--field is a one dimensional array, method described in the book "Programming in Lua 4th Edition", chapter 14, section "Matrices and Multi-Dimensional Arrays"
    check_cells = {},
    del_cells = {},
    cmd = ""
  }

  local function move(from, to)
    local tmp = self.f[to]
    self.f[to] = self.f[from]
    self.f[from] = tmp

    table.insert(self.check_cells, to)
    table.insert(self.check_cells, from)
  end

  local function mix()
    for i = 1, self.Y do
      local aux = (i-1) * self.X
      for j = 1, self.X do
        self.f[aux + j] = self.colors[math.random(1,6)]
      end
    end
  end

  local function dump()
    io.write("  _")
    for i = 0, self.Y-1 do
      io.write(i.."_")
    end
    io.write("\n")
    for i = 1, self.Y do
      io.write(i-1, "| ") -- i-1
      for j = 1, self.X do
        local cor = (i-1) * self.X + j
        io.write(self.f[cor].." ")
      end
      io.write("\n")
    end
    io.write("\n")
  end

  local function parse_command(c)
    if #c < 4 or not tonumber(c:sub(2,3)) or not self.directions:find(c:sub(-1)) then
      print("invalid command")
      return
    end
    return c:sub(2, 2)+1, c:sub(3, 3)+1, c:sub(4) -- +1
  end

  local function get_u_input()
    repeat
      io.write("> ")
      self.cmd = io.read()
      if self.cmd == 'q' then return end

      x,y,d = parse_command(self.cmd)
    until x or y or d

    local from = (y-1)*self.Y+x
    if d == 'u' then y = y-1
    elseif d == 'r' then x = x+1
    elseif d == 'd' then y = y+1
    elseif d == 'l' then x = x-1 end
    local to = (y-1)*self.Y+x

    if x > 0 and x <= self.X and y > 0 and y <= self.Y then
      return to, from
    end
    print("invalid move")
  end

  local function check3(random_n)
    local max_chain_len = 0
    local points = 0
    for _, i in ipairs(self.check_cells) do

      --horizontal
      local step = -1
      local right_bd, left_bd = i, i
      --print("checking left")--log
      while left_bd > 1 and left_bd < self.Y*self.X and left_bd~=1 and left_bd%10 ~= 1 and self.f[left_bd+step] == self.f[i] do
        left_bd = left_bd + step
        --e.g for special crystals (horizontal bomb)
        --can be show as "-A-"
        --if self.f[left_db+step] == "-A-" then
        --  left_db = tonumber(tostring(left_bd):sub(1,1)..'1')
        --  right_db = tonumber(tostring(left_bd):sub(1,1)..'0')+X
        --  break
        --end
      end

      step =1
      --print("checking right")--log
      while right_bd > 1 and right_bd < self.Y*self.X and right_bd%10 ~= 0 and self.f[right_bd+step] == self.f[i] do
        right_bd = right_bd + step
      end

      --print("horizontal borders: ", left_bd, right_bd)--log
      local chain_len = right_bd-left_bd
      max_chain_len = math.max(max_chain_len, chain_len)
      if right_bd-left_bd >= 2 then
        for j = left_bd, right_bd do
          table.insert(self.del_cells, j)
        end
      end

      --vertical
      step = -10
      local up_bd, down_bd = i, i
      --print("checking up")--log
      while up_bd > 1 and up_bd < self.Y*self.X and up_bd >=10 and self.f[up_bd+step] == self.f[i] do
        up_bd = up_bd + step
      end

      step = 10
      --print("checking down")--log
      while down_bd > 1 and down_bd < self.Y*self.X and down_bd < 91 and self.f[down_bd+step] == self.f[i] do
        down_bd = down_bd + step
      end

      --print("vertical borders: ", up_bd, down_bd)--log
      local chain_len = (down_bd-up_bd)//self.Y
      max_chain_len = math.max(max_chain_len, chain_len)
      if (down_bd-up_bd)//self.Y >= 2 then
        for j = up_bd, down_bd, self.Y do
          table.insert(self.del_cells, j)
        end
      end

      for j = 1, #self.del_cells do
        local replace = '-'
        if random_n ~= nil then replace = self.colors[math.random(1,6)] end
        self.f[self.del_cells[j]] = replace
        points = points + 1
      end

    end
    self.check_cells = {}

    return points, max_chain_len
  end

  local function lower_cristals()
    table.sort(self.del_cells)
    for _, i in ipairs(self.del_cells) do
      table.insert(self.check_cells, i)

      if self.f[i] ~= '-' then goto continue end
      local new_i = i
      while new_i > self.X do
        --print("swap ", nk, nk-X)--log
        self.f[new_i] = self.f[new_i - self.X]
        table.insert(self.check_cells, new_i)
        new_i = new_i - self.X
      end
      self.f[new_i] = self.colors[math.random(1,6)]
      table.insert(self.check_cells, i)
      dump()
      ::continue::
    end
    self.del_cells={}
  end

  local function check_field()
    for i=1, self.Y*self.X do
      table.insert(self.check_cells, i)
    end
    repeat
      local score, max_chain_len = check3(true)
      if max_chain_len == 0 and true then
        print("NO MOVES LEFT, MIXING")
        mix()
        for i=1, self.Y*self.X do
          table.insert(self.check_cells, i)
        end
      else
        self.check_cells = self.del_cells
        self.del_cells = {}
      end
    until score == 0 and max_chain_len == 1
  end

  local function tick()
    local points = check3()
    if points > 0 then
      repeat
        lower_cristals()
        local auto_points = check3()
        dump()
      until auto_points == 0
    else
      move(to, from)
    end
  end

  local function init()
    mix()
    repeat
      check_field()
      dump()
      from,to = get_u_input()
      if from and to then
        move(from, to)
        tick()
      end
    until self.cmd == 'q'
  end

  --public methods
  return {
    init = init,
    tick = tick,
    move = move,
    mix = mix,
    dump = dump,
  }

end

g = newGame()
g.init()
