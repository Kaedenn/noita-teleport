--[[
-- This file defines the core "Waypoint" functionality.
--]]

dofile("data/scripts/lib/utilities.lua")
local POI = dofile_once("mods/kae_waypoint/files/poi.lua")

Waypoint = {
    _categories = {},
    _w = {},
}

function Waypoint:new()
    local this = {}
    setmetatable(this, self)
    self.__index = self
    return self
end

function Waypoint:add(category, name, pos, extra)
    if self._w[category] == nil then
        self._w[category] = {}
        table.insert(self._categories, category)
    end
    table.insert(self._w[category], { name, pos, extra or {} })
end

--[[ Return a table {category, name, pos, extra} of all matching waypoints ]]
function Waypoint:lookup(category, name)
    local results = {}
    if category == nil then
        for _, catname in ipairs(self._categories) do
            for _, waypoint in ipairs(self:lookup(catname, nil)) do
                table.insert(results, {
                    caname,
                    waypoint[1],
                    waypoint[2],
                    waypoint[3] or {}
                })
            end
        end
    elseif self._w[category] ~= nil then
        for _, waypoint in ipairs(self._w[category]) do
            if name == nil or name == waypoint[1] then
                table.insert(results, {
                    category,
                    waypoint[1],
                    waypoint[2],
                    waypoint[3] or {}
                })
            end
        end
    end
    return results
end

--[[ Serialize all waypoints for storage to disk ]]
function Waypoint:serialize()
    local results = {}
    for _, waypoint in self:lookup(nil, nil) do
        local category = waypoint[1]
        local name = waypoint[2]
        local pos = waypoint[3]
        local extra = waypoint[4]
        local fields = {
            ("%q"):format(("%s"):format(waypoint[1])),
        }
    end
    return table.concat(results, ";")
end

--[[ Deserialize the given data ]]
function Waypoint:deserialize(data)
end

--[[ Helper functions not intended for public use ]]

--[[ Stringify the given value ]]
function Waypoint:_q(value)
end

--[[ Parse the given data ]]
function Waypoint:_p(data)

end

return Waypoint

-- vim: set ts=4 sts=4 sw=4 tw=79:
