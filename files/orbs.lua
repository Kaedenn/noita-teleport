--[[ Determine the teleport locations of every Orb. ]]

--[[
--TODO:
-- Add (collected) to parallel world orbs
--]]

dofile_once("data/scripts/lib/utilities.lua")

BIOME_EMPTY = "_EMPTY_"

Orbs = {}

--[[ORB_DATA = { -- [index] = {book, ng_biome[, ngplus_biome]}
    [0] = {"Thoth", "$biome_pyramid"},
    [1] = {"Volume I", "Mountain Altar"},
    -- (TODO: NG+ biome)
    [2] = {"Volume II", "$biome_vault_frozen"},
    -- Volume III is at index 7 (TODO: NG+ biome)
    [7] = {"Volume III", "$biome_lavacave"},
    -- Volume IV is at index 3 (TODO: NG+ biome)
    [3] = {"Volume IV", "$biome_sandcave"},
    -- Volume V is at index 8 (TODO: NG+ biome)
    [8] = {"Volume V", "$biome_wandcave"},
    -- Volume VI is at index 9 (TODO: NG+ biome)
    [9] = {"Volume VI", "$biome_rainforest_dark"},
    -- Volume VII is at index 10 (TODO: NG+ biome)
    [10] = {"Volume VII", "$biome_lava", "$biome_lake"},
    -- Volume VIII is at index 4 (both NG and NG+)
    [4] = {"Volume VIII", "$biome_boss_victoryroom"},
    -- Volume IX is at index 5 (TODO: NG+ biome)
    [5] = {"Volume IX", "$biome_winter_caves"},
    -- Volume X is at index 6
    [6] = {"Volume X", "$biome_wizardcave"},
}]]

--[[
-- The orb map is complicated, because GameGetOrbCollectedThisRun(idx) and
-- orb_map_get()[idx+1] do not agree.
--
-- Columns are:
--  NG orb index (for orb_map_get location) (TODO: verify)
--  NG+ orb index (for orb_map_get location)
--  orb ID (for GameGetOrbCollectedThisRun)
--  orb name
--  NG orb biome
--  NG+ orb biome, if static
--]]
ORB_MAP = { -- [ngindex, ng+index, orbid, name, ngbiome[, ng+biome]]
    {1, 1, 0, "Volume I", "Mountain Altar", "Mountain Altar"},
    {0, 0, 1, "Thoth", "$biome_pyramid", "$biome_pyramid"},
    {2, 2, 2, "Volume II", "$biome_vault_frozen"},
    {7, 7, 3, "Volume III", "$biome_lavacave"},
    {3, 3, 4, "Volume IV", "$biome_sandcave"},
    {8, 8, 5, "Volume V", "$biome_wandcave"},
    {9, 9, 6, "Volume VI", "$biome_rainforest_dark"},
    {10, 10, 7, "Volume VII", "$biome_lava", "$biome_lake"},
    {4, 4, 8, "Volume VIII", "$biome_boss_victoryroom", "$biome_boss_victoryroom"},
    {5, 5, 9, "Volume IX", "$biome_winter_caves"},
    {6, 6, 10, "Volume X", "$biome_wizardcave"}, 
}

Orb = {}
function Orb:new(odef)
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

-- TODO
function Orb:is_collected()
  return GameGetOrbCollectedThisRun(self._id)
end

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
    return

    --[[for _, orb_pos in ipairs(orb_map) do
        --print(("Orb %d at %d,%d"):format(onum, orb_pos[1], orb_pos[2]))
        local oidx = onum-1
        local orb_info = ORB_DATA[oidx]
        local orb_name = orb_info[1] or ("Orb %d"):format(oidx)
        local orb_biome = BiomeMapGetName(orb_pos[1], orb_pos[2])
        if orb_biome == BIOME_EMPTY then
            if newgame_n == 0 then
                orb_biome = orb_info[2]
            else
                orb_biome = ""
            end
        end
        table.insert(orb_list, Orb:new({
            oidx,
            orb_name,
            orb_biome,
            orb_pos
        }))
    end]]
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
