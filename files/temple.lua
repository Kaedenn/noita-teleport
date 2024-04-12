--[[ Determine the teleport locations of every Holy Mountain.
--
-- Taken mostly from cheatgui.
--
-- FIXME:
--  Collapsed feedback is inaccurate for NG+
--  Occasionally you're teleported just above the HM entry room (Snowy Depths)
-- TODO:
--  Determine if HM_COARSE_STEP/HM_FINE_MAX should be 512 instead of 500
--]]

Temples = {}

HM_COARSE_MIN = 0       -- Coarse: start at Y=0
HM_COARSE_MAX = 12000   -- Coarse: maximum vertical scan (last HM is ~13000)
HM_COARSE_STEP = 500    -- Coarse: vertical scan amount
HM_FINE_MAX = 500       -- Fine: maximum vertical scan
HM_FINE_ADJUST = 10     -- Fine: vertical scan amount
HM_ADJUST_DELTA = 200

HM_ABS_X = -677         -- data/entities/buildings/teleport_liquid_powered.xml
HM_REAL_X = -359        -- actual X coordinate; deduced experimentally
HM_REAL_ADJUST = -27    -- Y adjustment

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
            local ypos = refine_mountain_pos(y)
            table.insert(mountains, {prev_biome, ypos})
        else
            prev_biome = biome
        end
    end
    return mountains
end

--[[ From data/scripts/biomes/temple_shared.lua ]]
function temple_pos_to_id( pos_x, pos_y )
    local h = math.floor( pos_y / 512 )
    local w = math.floor( ( pos_x + (32*512) ) / (64*512) )
    local result = tostring(w) .. "_" .. tostring(h)
    return result
end

_temple_list = {
    -- {"name", {tele_x, tele_y}, {real_x, real_y}, "label"}
    {"$biome_excavationsite", {-200, 1330}, {-359, 1309}, "0_2"},
    {"$biome_snowcave", {-200, 2870}, {-359, 2843}, "0_5"},
    {"$biome_snowcastle", {-200, 4910}, {-359, 4891}, "0_9"},
    {"$biome_rainforest", {-200, 6450}, {-359, 6427}, "0_12"},
    {"$biome_vault", {-200, 8500}, {-359, 8475}, "0_16"},
    {"$biome_crypt", {-200, 10550}, {-359, 10523}, "0_20"},
}

-- The final temple is special
FINAL_TEMPLE = {"$biome_lava", {2300, 13110}, {2233, 13078}, "0_25"}

Temple = { }
function Temple:new(tdef)
    local this = {}
    setmetatable(this, { __index = self })

    if #tdef < 4 then error(("tdef[%d] < %d"):format(#tdef, 4)) end
    this._biome = tdef[1]
    this._tele_pos = tdef[2]
    this._real_pos = tdef[3]
    this._tid = tdef[4]

    return this
end

function Temple:as_poi(direct)
    --local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
    local name = self._biome
    if not direct and self:is_collapsed() then
        name = name .. " [Collapsed]" -- FIXME: inaccurate for NG+
    end
    return {name, self._tele_pos}
end

function Temple:is_leaked()
    return GlobalsGetValue("TEMPLE_LEAKED_" .. self._tid) == "1"
end

function Temple:is_collapsed()
    return GlobalsGetValue("TEMPLE_COLLAPSED_" .. self._tid) == "1"
end

function init_temple_list(temple_list)
    for _, tpair in ipairs(find_holy_mountains()) do
        local biome_name = tpair[1]
        local tele_pos = {HM_ABS_X, tpair[2]}
        local real_pos = {HM_REAL_X, tpair[2]+HM_REAL_ADJUST}
        local temple_id = temple_pos_to_id(HM_ABS_X, tpair[2])
        table.insert(temple_list, Temple:new({
            biome_name,
            tele_pos,
            real_pos,
            temple_id}))
    end
    table.insert(temple_list, Temple:new(FINAL_TEMPLE))
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
