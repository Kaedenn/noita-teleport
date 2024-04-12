--[[
-- This file defines the core "Waypoint" functionality.
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_waypoint/files/config.lua")
smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")

--[[ Serialization format version ]]
WP_VERSION_1 = 1
WP_VERSION = WP_VERSION_1

Waypoints = {}
function Waypoints:new()
    local this = {}
    setmetatable(this, { __index = self })

    self._data = {}

    return self
end

--[[ Add a new waypoint
-- Positional arguments:
--  [1] name        Waypoint name
--  [2] pos         Waypoint world coordinates as a table of two numbers
-- Keyword arguments:
--  category=str    Category name for grouping waypoints; optional
--  order=number    Sort ordering; optional; defaults to #waypoints
--  extra=table     Extra data to store along with the waypoint; optional
--]]
function Waypoints:add(data)
    table.insert(self._data, {
        name = data[1] or error("waypoint missing name"),
        wpos = data[2] or error("waypoint missing position"),
        category = data.category or "",
        order = data.order or #self._data,
        extra = data.extra or {}
    })
end

--[[ Merge waypoints into the given POI table ]]
function Waypoints:merge(poi)
    local uncat = {}
    local by_cats = {}
    for _, entry in ipairs(self._data) do
        if entry.category == "" then
            table.insert(uncat, entry)
        elseif by_cats[entry.category] == nil then
            by_cats[entry.category] = {entry}
        else
            table.insert(by_cats[entry.category], entry)
        end
    end

    local function sort_entry(left, right)
        if left.order == right.order then
            return left.name < right.name
        end
        return left.order < right.order
    end

    table.sort(uncat, sort_entry)
    for catname, _ in pairs(by_cats) do
        table.sort(by_cats[catname], sort_entry)
    end
    for _, entry in ipairs(uncat) do
        table.insert(poi, {entry.name, entry.wpos})
    end
    for catname, entries in pairs(by_cats) do
        local poi_entry = {catname, l = {}}
        for _, entry in ipairs(entries) do
            table.insert(poi_entry.l, {entry.name, entry.wpos})
        end
        table.insert(poi, poi_entry)
    end
end

--[[ Save the waypoint data to the game settings ]]
function Waypoints:save_data()
    local save_key = ("%s.%s"):format(MOD_ID, "waypoints")
    local save_text = smallfolk.dumps({
        version = WP_VERSION,
        data = self._data
    })
    ModSettingSetNextValue(save_key, save_text, false)
end


--[[ (Private) load waypoint data v1 ]]
function _wp_load_v1(wp, data, merge)
    if merge ~= true then wp._data = {} end
    for _, entry in ipairs(data) do
        table.insert(wp._data, entry)
    end
end

--[[ Load the waypoint data from the game settings ]]
function Waypoints:load_data(merge)
    local save_key = ("%s.%s"):format(MOD_ID, "waypoints")
    local save_text = ModSettingGet(save_key)
    if not save_text or save_text == "" then return false end
    local data = smallfolk.loads(save_text)
    if data.version == WP_VERSION_1 then
        _wp_load_v1(self, data.data, merge)
        return true
    end
    GamePrint(("Invalid/unsupported waypoint version %s"):format(tostring(data.version)))
    return false
end

return Waypoints

-- vim: set ts=4 sts=4 sw=4 tw=79:
