-- wonders.lua
-- Author: Chris Carucci (https://github.com/ChrisCarucci)
-- Usage: wonders <type> <x> <y> [size] [material] [--instant]
-- Or run without args for GUI in fortress mode
-- Supports: giza, quetzalcoatl, lighthouse, stonehenge, greatwall,
--           colossus, ziggurat, oracle, obelisk, library, zeus

local gui = require('gui')
local widgets = require('gui.widgets')
local guidm = require('gui.dwarfmode')

local args = {...}

-- GUI Mode if no arguments provided
if #args == 0 and dfhack.world.isFortressMode() then
  local WonderGUI = defclass(WonderGUI, guidm.MenuOverlay)
  
  function WonderGUI:init()
    self.wonder_types = {
      {id='giza', name='Giza Pyramid', desc='Hollow Egyptian pyramid', cost=500},
      {id='quetzalcoatl', name='Quetzalcoatl Pyramid', desc='Stepped Mesoamerican pyramid', cost=800},
      {id='lighthouse', name='Lighthouse', desc='Tall beacon tower', cost=300},
      {id='stonehenge', name='Stonehenge', desc='Circle of standing stones', cost=200},
      {id='greatwall', name='Great Wall', desc='Fortified wall with towers', cost=1000},
      {id='colossus', name='Colossus', desc='Massive warrior statue', cost=600},
      {id='ziggurat', name='Ziggurat', desc='Stepped pyramid with altar', cost=700},
      {id='oracle', name='Oracle Temple', desc='Columned temple', cost=400},
      {id='obelisk', name='Obelisks', desc='Four tall stone columns', cost=150},
      {id='library', name='Great Library', desc='Multi-story library', cost=450},
      {id='zeus', name='Temple of Zeus', desc='Grand Greek temple', cost=900}
    }
    
    self:addviews{
      widgets.Window{
        frame={w=50, h=25},
        frame_title='Wonder Builder',
        subviews={
          widgets.List{
            view_id='wonder_list',
            frame={t=1, l=1, r=1, b=8},
            choices=self.wonder_types,
            text_pen=COLOR_WHITE,
            cursor_pen=COLOR_YELLOW,
            on_submit=self:callback('selectWonder'),
            on_select=self:callback('updateCost')
          },
          widgets.Label{
            view_id='cost_label',
            frame={t=10, l=1},
            text='Material Cost: 0'
          },
          widgets.Label{frame={t=15, l=1}, text='Size:'},
          widgets.CycleHotkeyLabel{
            view_id='size_cycle',
            frame={t=15, l=7, w=15},
            options={'small', 'medium', 'large'},
            initial_option=2,
            on_change=self:callback('updateCost')
          },
          widgets.Label{frame={t=17, l=1}, text='Material:'},
          widgets.EditField{
            view_id='material_edit',
            frame={t=17, l=11, w=15},
            text='GRANITE'
          },
          widgets.Label{frame={t=19, l=1}, text='Build Mode:'},
          widgets.CycleHotkeyLabel{
            view_id='build_mode',
            frame={t=19, l=13, w=20},
            options={'Manual (with cost)', 'Instant (no cost)'},
            initial_option=1,
            on_change=self:callback('updateCost')
          },
          widgets.HotkeyLabel{
            frame={t=22, l=1},
            label='Place Wonder',
            key='SELECT',
            on_activate=self:callback('buildWonder')
          },
          widgets.HotkeyLabel{
            frame={t=22, l=20},
            label='Cancel',
            key='LEAVESCREEN',
            on_activate=self:callback('dismiss')
          }
        }
      }
    }
  end
  
  function WonderGUI:selectWonder(idx, choice)
    self.selected_wonder = choice.id
  end
  
  function WonderGUI:updateCost(idx, choice)
    local selected_idx = self.subviews.wonder_list:getSelected()
    local selected = choice or (selected_idx and self.wonder_types[selected_idx])
    if selected then
      local size = self.subviews.size_cycle:getOptionValue()
      local build_mode = self.subviews.build_mode:getOptionValue()
      local multiplier = size == 'small' and 0.5 or size == 'large' and 2 or 1
      local cost = math.floor(selected.cost * multiplier)
      
      if build_mode == 'Instant (no cost)' then
        self.subviews.cost_label:setText('Material Cost: FREE (instant build)')
      else
        self.subviews.cost_label:setText('Material Cost: ' .. cost .. ' blocks + citizens')
      end
    end
  end
  
  function WonderGUI:buildWonder()
    if not self.selected_wonder then
      dfhack.printerr('Please select a wonder type')
      return
    end
    
    -- Validate material
    local material = self.subviews.material_edit.text
    if not dfhack.matinfo.find(material) then
      dfhack.printerr('Invalid material: ' .. material)
      return
    end
    
    -- Store build parameters
    self.build_size = self.subviews.size_cycle:getOptionValue()
    self.build_material = material
    self.build_instant = self.subviews.build_mode:getOptionValue() == 'Instant (no cost)'
    
    self:dismiss()
    
    -- Enter placement mode
    dfhack.print('Click on the map to place your ' .. self.selected_wonder .. ' wonder...')
    
    local PlacementOverlay = defclass(PlacementOverlay, guidm.MenuOverlay)
    
    function PlacementOverlay:init(parent)
      self.parent_gui = parent
      self.selected_pos = nil
      
      self:addviews{
        widgets.Window{
          frame={w=30, h=8, r=2, t=2},
          frame_title='Confirm Placement',
          visible=false,
          view_id='confirm_window',
          subviews={
            widgets.Label{
              frame={t=1, l=1},
              text='Place wonder here?'
            },
            widgets.HotkeyLabel{
              frame={t=3, l=1},
              label='Confirm',
              key='SELECT',
              on_activate=self:callback('confirmPlacement')
            },
            widgets.HotkeyLabel{
              frame={t=3, l=12},
              label='Cancel',
              key='LEAVESCREEN',
              on_activate=self:callback('cancelPlacement')
            }
          }
        }
      }
    end
    
    function PlacementOverlay:onInput(keys)
      if keys._MOUSE_L_DOWN and not self.subviews.confirm_window.visible then
        local pos = dfhack.gui.getMousePos()
        if pos then
          self.selected_pos = pos
          self.subviews.confirm_window.visible = true
        end
      elseif keys.LEAVESCREEN and not self.subviews.confirm_window.visible then
        self:dismiss()
      end
    end
    
    function PlacementOverlay:confirmPlacement()
      if self.selected_pos then
        local build_args = {self.parent_gui.selected_wonder, tostring(self.selected_pos.x), tostring(self.selected_pos.y), 
                           self.parent_gui.build_size, self.parent_gui.build_material}
        if self.parent_gui.build_instant then 
          table.insert(build_args, '--instant') 
        end
        
        dfhack.run_script('wonders', table.unpack(build_args))
        self:dismiss()
      end
    end
    
    function PlacementOverlay:cancelPlacement()
      self.subviews.confirm_window.visible = false
      self.selected_pos = nil
    end
    
    function PlacementOverlay:onRenderBody()
      -- Show placement cursor
      local pos = dfhack.gui.getMousePos()
      if pos then
        dfhack.screen.paintString({fg=COLOR_YELLOW}, pos.x, pos.y, 'X')
      end
    end
    
    PlacementOverlay(self):show()
  end
  
  WonderGUI():show()
  return
end

-- Command line mode
if #args < 3 then
  qerror("Usage: wonders <type> <x> <y> [size/custom dims] [material] [--instant]\nOr run without args for GUI in fortress mode")
end

local wonder = args[1]:lower()
local x, y = tonumber(args[2]), tonumber(args[3])
local size_opt, mat_str, instant = 'medium', 'GRANITE', false

for i = 4, #args do
  local arg = args[i]:lower()
  if arg == '--instant' or arg == '--complete' then
    instant = true
  elseif not tonumber(arg) and dfhack.matinfo.find(arg) then
    mat_str = arg
  elseif arg == 'small' or arg == 'medium' or arg == 'large' then
    size_opt = arg
  end
end

local mat = dfhack.matinfo.find(mat_str)
if not mat then qerror("Invalid material: " .. mat_str) end

-- Default sizes
local size_map = {
  small = {l=10, w=10, h=7},
  medium = {l=18, w=18, h=12},
  large = {l=26, w=26, h=18},
}

local dims = size_map[size_opt] or {l=18, w=18, h=12}

-- Tile placement
local function setTile(x, y, z)
  local block = dfhack.maps.ensureTileBlock(x, y, z)
  block.designation[x%16][y%16].hidden = false
  if instant then
    block.tiletype[x%16][y%16] = df.tiletype.ConstructedFloor
    block.material[x%16][y%16] = mat.index
  else
    dfhack.run_script('build', 'floor', x, y, z, mat_str)
  end
end

-- ═══════════════════════════════════════════════════════════════
--                          GIZA PYRAMID
-- ═══════════════════════════════════════════════════════════════
local function buildPyramid(x, y, dims, hollow, mat, instant)
  for z = 0, dims.h - 1 do
    local sz = dims.l - (z * 2)
    for dx = 0, sz - 1 do
      for dy = 0, sz - 1 do
        local edge = dx == 0 or dy == 0 or dx == sz-1 or dy == sz-1
        if not hollow or edge then
          setTile(x - math.floor(sz/2) + dx, y - math.floor(sz/2) + dy, z)
        end
      end
    end
    -- Central ramp
    setTile(x, y, z)
  end
end


-- ═══════════════════════════════════════════════════════════════
--                      QUETZALCOATL PYRAMID
-- ═══════════════════════════════════════════════════════════════
local function buildSteppedPyramid(x, y, dims, mat, instant)
  for z = 0, dims.h - 1 do
    local sz = dims.l - (z * 2)
    for dx = 0, sz - 1 do
      for dy = 0, sz - 1 do
        setTile(x - math.floor(sz / 2) + dx, y - math.floor(sz / 2) + dy, z)
      end
    end
  end
  -- Temple cap floor
  for dx = -1, 1 do
    for dy = -1, 1 do
      setTile(x + dx, y + dy, dims.h)
    end
  end
end


-- ═══════════════════════════════════════════════════════════════
--                         LIGHTHOUSE
-- ═══════════════════════════════════════════════════════════════
local function buildLighthouse(x, y, dims, mat, instant)
  local height = dims.h or 15
  -- Base platform
  for dx = -3, 3 do
    for dy = -3, 3 do
      setTile(x + dx, y + dy, 0)
    end
  end
  -- Tower shaft
  for z = 1, height - 3 do
    for dx = -1, 1 do
      for dy = -1, 1 do
        local edge = dx == -1 or dx == 1 or dy == -1 or dy == 1
        if edge then
          setTile(x + dx, y + dy, z)
        end
      end
    end
  end
  -- Beacon chamber
  for z = height - 2, height do
    for dx = -2, 2 do
      for dy = -2, 2 do
        setTile(x + dx, y + dy, z)
      end
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
--                         STONEHENGE
-- ═══════════════════════════════════════════════════════════════
local function buildStonehenge(x, y, mat, instant)
  local radius = 8
  local stones = 12
  for i = 0, stones - 1 do
    local angle = (i * 2 * math.pi) / stones
    local sx = x + math.floor(radius * math.cos(angle))
    local sy = y + math.floor(radius * math.sin(angle))
    -- Vertical stones
    for z = 0, 4 do
      setTile(sx, sy, z)
      setTile(sx + 1, sy, z)
    end
    -- Lintels every other stone
    if i % 2 == 0 and i < stones - 1 then
      local next_angle = ((i + 1) * 2 * math.pi) / stones
      local ex = x + math.floor(radius * math.cos(next_angle))
      local ey = y + math.floor(radius * math.sin(next_angle))
      local steps = math.max(math.abs(ex - sx), math.abs(ey - sy))
      for step = 0, steps do
        local lx = sx + math.floor((ex - sx) * step / steps)
        local ly = sy + math.floor((ey - sy) * step / steps)
        setTile(lx, ly, 5)
      end
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
--                         GREAT WALL
-- ═══════════════════════════════════════════════════════════════
local function buildWall(x, y, dims, mat, instant)
  local length = dims.l or 50
  local height = dims.h or 8
  for i = 0, length - 1 do
    for z = 0, height - 1 do
      setTile(x + i, y, z)
      setTile(x + i, y + 1, z)
      -- Watchtowers every 10 segments
      if i % 10 == 0 then
        for dz = 0, 3 do
          for dy = -1, 2 do
            setTile(x + i, y + dy, height + dz)
          end
        end
      end
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
--                           COLOSSUS
-- ═══════════════════════════════════════════════════════════════
local function buildColossus(x, y, mat, instant)
  -- Base platform
  for dx = -4, 4 do
    for dy = -4, 3 do
      setTile(x + dx, y + dy, 0)
    end
  end
  -- Feet
  for dx = -2, 2 do
    for dy = -3, -1 do
      setTile(x + dx, y + dy, 1)
    end
  end
  -- Left leg
  for z = 2, 19 do
    setTile(x - 1, y - 2, z)
  end
  -- Right leg  
  for z = 2, 19 do
    setTile(x + 1, y - 2, z)
  end
  -- Torso
  for z = 20, 24 do
    for dx = -1, 1 do
      for dy = -1, 1 do
        setTile(x + dx, y + dy, z)
      end
    end
  end
  -- Head
  for z = 25, 28 do
    for dx = -1, 1 do
      for dy = 0, 2 do
        setTile(x + dx, y + dy, z)
      end
    end
  end
  -- Left arm with shield
  for z = 21, 24 do
    setTile(x - 2, y, z)
  end
  -- Shield
  for z = 21, 24 do
    for dx = -4, -3 do
      for dy = 0, 1 do
        setTile(x + dx, y + dy, z)
      end
    end
  end
  -- Right arm with spear
  for z = 21, 24 do
    setTile(x + 2, y, z)
  end
  -- Spear shaft
  for z = 0, 30 do
    setTile(x + 3, y, z)
  end
end

-- ═══════════════════════════════════════════════════════════════
--                           ZIGGURAT
-- ═══════════════════════════════════════════════════════════════
local function buildZiggurat(x, y, dims, mat, instant)
  local base = dims.l
  local steps = dims.h
  for step = 0, steps - 1 do
    local width = base - (step * 2)
    for dx = 0, width - 1 do
      for dy = 0, width - 1 do
        setTile(x - math.floor(width / 2) + dx, y - math.floor(width / 2) + dy, step)
      end
    end
  end
  -- Central altar
  for dx = -1, 1 do for dy = -1, 1 do setTile(x + dx, y + dy, steps) end end
end

-- ═══════════════════════════════════════════════════════════════
--                        ORACLE TEMPLE
-- ═══════════════════════════════════════════════════════════════
local function buildOracleTemple(x, y, mat, instant)
  local w = 10
  local l = 16
  for dx = -w, w, 4 do
    for dy = -l, l, 4 do
      for z = 0, 4 do
        setTile(x + dx, y + dy, z) -- Pillars
      end
    end
  end
  -- Inner chamber
  for dx = -2, 2 do
    for dy = -2, 2 do
      for z = 0, 2 do
        setTile(x + dx, y + dy, z)
      end
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
--                           OBELISKS
-- ═══════════════════════════════════════════════════════════════
local function buildObelisks(x, y, dims, mat, instant)
  local h = dims.h or 10
  local offsets = {{-5, -5}, {5, -5}, {-5, 5}, {5, 5}}
  for _, offset in ipairs(offsets) do
    for z = 0, h - 1 do
      setTile(x + offset[1], y + offset[2], z)
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
--                        GREAT LIBRARY
-- ═══════════════════════════════════════════════════════════════
local function buildLibrary(x, y, mat, instant)
  local w, l, h = 10, 16, 6
  for z = 0, h - 1 do
    for dx = -w, w do
      for dy = -l, l do
        if dx == -w or dx == w or dy == -l or dy == l then
          setTile(x + dx, y + dy, z) -- Outer walls
        elseif z % 2 == 0 and dx % 4 == 0 then
          setTile(x + dx, y + dy, z) -- Shelves
        end
      end
    end
  end
  -- Reading table on top
  for dx = -1, 1 do for dy = -1, 1 do setTile(x+dx, y+dy, h) end end
end

-- ═══════════════════════════════════════════════════════════════
--                        TEMPLE OF ZEUS
-- ═══════════════════════════════════════════════════════════════
local function buildTempleOfZeus(x, y, dims, mat, instant)
  local w, l = 15, 30
  -- Base platform
  for dx = -w-2, w+2 do
    for dy = -l-2, l+2 do
      setTile(x + dx, y + dy, 0)
    end
  end
  -- Outer columns
  for i = -l, l, 6 do
    for z = 1, 8 do
      setTile(x - w, y + i, z) -- Left columns
      setTile(x + w, y + i, z) -- Right columns
    end
  end
  for i = -w, w, 6 do
    for z = 1, 8 do
      setTile(x + i, y - l, z) -- Front columns
      setTile(x + i, y + l, z) -- Back columns
    end
  end
  -- Roof structure
  for z = 9, 12 do
    for dx = -w-1, w+1 do
      setTile(x + dx, y - l-1, z) -- Front roof
      setTile(x + dx, y + l+1, z) -- Back roof
    end
    for dy = -l-1, l+1 do
      setTile(x - w-1, y + dy, z) -- Left roof
      setTile(x + w+1, y + dy, z) -- Right roof
    end
  end
  -- Inner chamber floor
  for dx = -w+3, w-3 do
    for dy = -l+3, l-3 do
      setTile(x + dx, y + dy, 1)
    end
  end
end

-- Dispatcher
if wonder == 'giza' then
  buildPyramid(x, y, dims, true, mat, instant)
elseif wonder == 'quetzalcoatl' then
  buildSteppedPyramid(x, y, dims, mat, instant)
elseif wonder == 'lighthouse' then
  buildLighthouse(x, y, dims, mat, instant)
elseif wonder == 'stonehenge' then
  buildStonehenge(x, y, mat, instant)
elseif wonder == 'greatwall' then
  buildWall(x, y, dims, mat, instant)
elseif wonder == 'colossus' then
  buildColossus(x, y, mat, instant)
elseif wonder == 'ziggurat' then
  buildZiggurat(x, y, dims, mat, instant)
elseif wonder == 'oracle' then
  buildOracleTemple(x, y, mat, instant)
elseif wonder == 'obelisk' or wonder == 'obelisks' then
  buildObelisks(x, y, dims, mat, instant)
elseif wonder == 'library' then
  buildLibrary(x, y, mat, instant)
elseif wonder == 'zeus' then
  buildTempleOfZeus(x, y, dims, mat, instant)
else
  qerror("Unknown wonder type: " .. wonder)
end

print("✨ Constructed wonder: " .. wonder .. " at [" .. x .. ", " .. y .. "] using " .. mat_str .. (instant and " (instant build)" or " (scheduled jobs)"))
