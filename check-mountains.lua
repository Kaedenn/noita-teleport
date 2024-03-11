--[[ Determine the teleport locations of every Holy Mountain.
--
-- Taken mostly from cheatgui.
--
--]]

HM_COARSE_MIN = 0
HM_COARSE_MAX = 15000
HM_COARSE_STEP = 500
HM_FINE_MAX = 500
HM_FINE_ADJUST = 10
HM_ADJUST_DELTA = 200

HM_ABS_X = -677 -- See data/entities/buildings/teleport_liquid_powered.xml
HM_REAL_X = -359 -- Deduced experimentally
HM_REAL_ADJUST = -27

--[[ Find the exact Y position from a relative one.
--
-- This works by finding the bottom edge of a Holy Mountain and subtracting
-- 200 pixels.
--
--]]
function refine_mountain_pos(y0)
  for y = y0, y0+HM_FINE_MAX, HM_FINE_ADJUST do
    local biome = BiomeMapGetName(0, y)
    if biome ~= "$biome_holymountain" then
      return y-HM_FINE_ADJUST - HM_ADJUST_DELTA
    end
  end
  return y0
end

--[[ Find all of the center world Holy Mountains.
--
-- Returns an array of {biome_name, teleport_y_pos}
--]]
function find_holy_mountains()
  local prev_biome = "?"
  local mountains = {}
  for y = HM_COARSE_MIN, HM_COARSE_MAX, HM_COARSE_STEP do
    local biome = BiomeMapGetName(0, y)
    if biome == "$biome_holymountain" then
      table.insert(mountains, {prev_biome, refine_mountain_pos(y)})
    else
      prev_biome = biome
    end
  end
  return mountains
end

for _, mpair in ipairs(find_holy_mountains()) do
  print(("%s: -677,%s (%s)"):format(mpair[1], tostring(mpair[2]), tostring(mpair[3])))
end
