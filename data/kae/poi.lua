--[[ Provide mods the ability to add custom places ]]

--[[ Build a string for the POI, for diagnostics ]]
function _entry_to_string(entry)
    local label = entry[1]
    if entry.group then
        label = ("%s/%s"):format(entry.group, label)
    end
    return label
end

--[[ Serialize an entries table ]]
function _encode_places(entries)
    local smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")
    return smallfolk.dumps(entries)
end

--[[ Deserialize an entries table ]]
function _decode_places(entries)
    local smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")
    return smallfolk.loads(entries)
end

--[[ Load the POI table from mod storage; returns {} if one isn't present ]]
function _get_places()
    local key = "kae_waypoint._places"
    local data = ModSettingGet(key)
    local new_data = ModSettingGetNextValue(key)
    if new_data ~= nil and data ~= new_data then
        data = new_data
    end

    if data ~= nil then
        return _decode_places(data)
    end
    return {}
end

--[[ Save the POI table to mod storage ]]
function _save_places(places)
    local key = "kae_waypoint._places"
    local data = _encode_places(places)
    ModSettingSetNextValue(key, data, false)
    force_places_update()
end

--[[ Validate the entry and return a well-formed POI ]]
function _create_poi(entry)
    local error_msg = nil
    if type(entry) ~= "table" then
        error_msg = ("%s not table"):format(type(entry))
    elseif #entry < 2 then
        error_msg = "missing required fields"
    elseif type(entry[1]) ~= "string" then
        error_msg = ("label %s not string"):format(type(entry[1]))
    elseif type(entry[2]) ~= "table" then
        error_msg = ("coords %s not table"):format(type(entry[2]))
    elseif #entry[2] ~= 2 and #entry[2] ~= 3 then
        error_msg = ("#coords %d not 2 or 3"):format(#entry[2])
    end
    if error_msg ~= nil then return nil, error_msg end

    local label = entry[1]
    local coords = entry[2]
    local xpos, ypos = coords[1], coords[2]
    if type(xpos) ~= "number" or type(ypos) ~= "number" then
        error_msg = ("coords %q,%q not numbers"):format(tostring(xpos), tostring(ypos))
    end
    if error_msg ~= nil then return nil, error_msg end

    local result = {label, {xpos, ypos}}
    if #coords == 3 then
        local wpos = coords[2]
        if type(wpos) ~= "number" then
            error_msg = ("world %q not number"):format(tostring(wpos))
        else
            table.insert(result[2], wpos)
        end
    end
    if error_msg ~= nil then return nil, error_msg end

    if type(entry.group) == "string" then
        result.group = entry.group
    end
    return result, nil
end

--[[ True if the two POIs go to the same place
-- world=nil will match all locations regardless of world.
--]]
function _is_same_location(entry1, entry2)
    local ex, ey = entry1[2][1], entry1[2][2]
    local ew = entry1[2][3]
    local nx, ny = entry2[2][1], entry2[2][2]
    local nw = entry2[2][3]
    if ex == nx and ey == ny then
        if ew == nil or nw == nil or ew == nw then
            return true
        end
    end
    return false
end

--[[ True if the given POI duplicates another POI ]]
function _is_duplicate_entry(entries, new_entry)
    for _, entry in ipairs(entries) do
        if _is_same_location(entry, new_entry) then
            return true, entry
        end
    end
    return false, nil
end

--[[
-- Add a new place to the PLACES table.
--
-- add_places_entry({"My Place", {100, 100}})
-- add_places_entry({"My Place", {100, 100, 1}})
-- add_places_entry({"My Place", {100, 100}, group="My Places"})
--
-- Returns status:true, error_message:nil on success.
-- Returns status:false, error_message:string on error.
--]]
function add_places_entry(entry)
    local entries = _get_places()
    local new_entry, error_msg = _create_poi(entry)
    if new_entry ~= nil then
        local duplicates, duplicate = _is_duplicate_entry(entries, new_entry)
        if duplicates then
            return false, ("entry %s duplicates %s"):format(
                new_entry[1], _entry_to_string(duplicate))
        end
        table.insert(entries, new_entry)
        _save_places(entries)
        return true, nil
    end
    return false, ("malformed entry: %s"):format(error_msg)
end

--[[ Simpler functions for common use cases ]]

--[[ Add a simple place of interest.
--
-- add_poi("My Place", 100, 100)
-- add_poi("My Place", 100, 100, 0) -- equivalent
-- add_poi("My Place", 100, 100, 1) -- east parallel world
--
-- Returns true, nil on success.
-- Returns false, error:string on error.
--]]
function add_poi(name, x, y, world)
    local coord = {x, y}
    if world then coord = {x, y, world} end
    local result, error_msg = add_places_entry({name, coord})
    return result, error_msg
end

--[[ Add a simple place of interest to a group.
--
-- add_poi("My Places", "My Place", 100, 100)
-- add_poi("My Places", "My Place", 100, 100, 1) -- east parallel world
--
-- Returns true, nil on success.
-- Returns false, error:string on error.
--]]
function add_grouped_poi(group, name, x, y, world)
    local coord = {x, y}
    if world then coord = {x, y, world} end
    local result, error_msg = add_places_entry({name, coord, group=group})
    return result, error_msg
end

--[[ Remove all matching place-of-interest entries.
--
-- Returns true on success (at least one match).
-- Returns false on error (zero matches).
--]]
function remove_poi(name) -- TODO: support table labels
    local entries = _get_places()
    local remains = {}
    for _, entry in ipairs(entries) do
        local label = entry[1]
        if label ~= name then
            table.insert(remains, entry)
        end
    end
    if #remains ~= #entries then
        _save_places(remains)
        return true
    end
    return false
end

--[[ Remove all matching place-of-interest groups.
--
-- Returns true on success (at least one match).
-- Returns false on error (zero matches).
--]]
function remove_poi_group(group)
    local entries = _get_places()
    local remains = {}
    for _, entry in ipairs(entries) do
        if not entry.group or entry.group ~= group then
            table.insert(remains, entry)
        end
    end
    if #remains ~= #entries then
        _save_places(remains)
        return true
    end
    return false
end

--[[ Remove any POI with the given (exact!) teleport destination ]]
function remove_poi_at(x, y, world)
    local coord = {x, y}
    if world then coord = {x, y, world} end
    local temp_poi = {nil, coord}
    local entries = _get_places()
    local remains = {}
    for idx, entry in ipairs(entries) do
        if not _is_same_location(temp_poi, entry) then
            table.insert(remains, entry)
        end
    end
    if #remains ~= #entries then
        _save_places(remains)
        return true
    end
    return false
end

--[[ Force an update ]]
function force_places_update()
    GlobalsSetValue("kae_waypoint_force_update", "1")
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
