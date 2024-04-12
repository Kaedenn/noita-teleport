--[[ This file can be used with LuaJIT standalone to test POI ]]

dofile("mods/kae_waypoint/files/poi.lua")

function get_poi_byname(name)
    for idx, entry in ipairs(PLACES) do
        if entry[1] == name then
            return entry
        end
    end
    return nil
end

local poi_spawn = get_poi_byname("Spawn")
local poi_spawn2 = PLACES["Spawn"]
assert(poi_spawn ~= nil, "get_poi_byname(Spawn)")
assert(poi_spawn2 ~= nil, "get_poi by __index")
assert(poi_spawn[1] == poi_spawn2[1])

-- vim: set ts=4 sts=4 sw=4:

