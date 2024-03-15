--[[ Determine the teleport locations of every Orb. ]]

--[[
--TODO:
-- Add (collected) to parallel world orbs
--]]

dofile_once("data/scripts/lib/utilities.lua")

BIOME_EMPTY = "_EMPTY_"

Orbs = {}

--[[
-- The orb map is complicated, because GameGetOrbCollectedThisRun(idx) and
-- orb_map_get()[idx+1] do not agree.
--
-- Columns are:
--  NG orb index (for orb_map_get location)
--  NG+ orb index (for orb_map_get location)
--  orb ID (for GameGetOrbCollectedThisRun)
--  orb name (really, the book's name)
--  NG orb biome
--  NG+ orb biome, if static (optional)
--]]
ORB_MAP = { -- [ngindex, ng+index, orbid, name, ngbiome[, ng+biome]]
    {1, 1, 0, "Volume I", "Mountain Altar", "Mountain Altar"},
    {10, 0, 1, "Thoth", "$biome_pyramid", "$biome_pyramid"},
    {5, 2, 2, "Volume II", "$biome_vault_frozen"},
    {9, 7, 3, "Volume III", "$biome_lavacave"},
    {8, 3, 4, "Volume IV", "$biome_sandcave"},
    {2, 8, 5, "Volume V", "$biome_wandcave"},
    {3, 9, 6, "Volume VI", "$biome_rainforest_dark"},
    {0, 10, 7, "Volume VII", "$biome_lava", "$biome_lake"},
    {6, 4, 8, "Volume VIII", "$biome_boss_victoryroom", "$biome_boss_victoryroom"},
    {4, 5, 9, "Volume IX", "$biome_winter_caves"},
    {7, 6, 10, "Volume X", "$biome_wizardcave"}, 
}

Orb = {}
function Orb:new(odef) -- {id, name, biome, opos, wpos}
    local this = {}
    setmetatable(this, { __index = self })
    this._id = odef[1]
    this._name = odef[2]
    this._biome = odef[3] or ""
    this._orb_pos = odef[4]
    this._real_pos = {
        odef[4][1] * 512 + 256,
        odef[4][2] * 512 + 256
    }
    return this
end

--[[ Return {label, {wx, wy}} for this orb ]]
function Orb:as_poi()
    local name = self._name
    if self._biome ~= "" and self._biome ~= BIOME_EMPTY then
        name = ("%s (%s)"):format(name, self._biome)
    end
    if self:is_collected() then
        name = ("%s (collected)"):format(name)
    end
    return {name, self._real_pos}
end

--[[ True if this orb is collected ]]
function Orb:is_collected()
  return GameGetOrbCollectedThisRun(self._id)
end

--[[ Initialize the orb list given as an argument ]]
function init_orb_list(orb_list)
    local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
    local orb_map = orb_map_get()
    for _, orb_def in ipairs(ORB_MAP) do
        local orb_num = orb_def[1]
        if orb_num+1 > #orb_map then break end
        if newgame_n > 0 then orb_num = orb_def[2] end
        local orb_pos = orb_map[orb_num+1]
        local orb_name = orb_def[4]
        local orb_biome = BiomeMapGetName(orb_pos[1], orb_pos[2])
        if orb_biome == BIOME_EMPTY then
            if newgame_n == 0 then
                orb_biome = orb_def[5]
            else
                orb_biome = orb_def[6] or ""
            end
        end
        table.insert(orb_list, Orb:new({
            orb_def[3],
            orb_name,
            orb_biome,
            orb_pos
        }))
    end
end

--[[ Orb validation snippet with kae_test
omap = orb_map_get()
self.host:text_clear()
tele_idx = 10
for idx, opos in ipairs(omap) do
  local biome = BiomeMapGetName(opos[1], opos[2]-1)
  local wx = opos[1] * 512 + 256
  local wy = opos[2] * 512 + 256
  print(("%d at {%d,%d} {%d, %d} in %s"):format(idx-1, opos[1], opos[2], wx, wy, biome))
  local player = get_players()[1]
  if tele_idx and tele_idx == idx-1 then
    EntitySetTransform(player, wx, wy)
    print(("Teleporting to orb %d"):format(idx-1))
  end
end
--]]

-- vim: set ts=4 sts=4 sw=4 tw=79:
