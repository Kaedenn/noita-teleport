--[[ Provide mods the ability to add custom places ]]

dofile_once("data/scripts/lib/utilities.lua")

--[[ Flatten a (possibly nested) table of strings ]]
function _flatten_table(tbl, sep)
    local entries = {}
    for _, entry in ipairs(tbl) do
        local item = entry
        if type(item) == "table" then
            item = _flatten_table(entry, sep or " ")
        elseif type(item) ~= "string" then
            item = tostring(entry)
        end
        table.insert(entries, item)
    end
    return table.concat(entries, sep or " ")
end

--[[ Build a string for the POI, for diagnostics ]]
function _entry_to_string(entry)
    local label = entry[1]
    if type(label) == "table" then
        label = _flatten_table(label)
    end
    local group = entry.group
    if type(group) == "table" then
        group = _flatten_table(group)
    end
    if group then
        label = ("%s/%s"):format(group, label)
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
    elseif type(entry[1]) ~= "string" and type(entry[1]) ~= "table" then
        error_msg = ("label %s not string or table"):format(type(entry[1]))
    elseif type(entry[2]) ~= "table" then
        error_msg = ("coords %s not table"):format(type(entry[2]))
    elseif #entry[2] ~= 2 and #entry[2] ~= 3 then
        error_msg = ("#coords %d not 2 or 3"):format(#entry[2])
    end
    if error_msg ~= nil then return nil, error_msg end

    local label, coords = unpack(entry)
    local xpos, ypos = coords[1], coords[2]
    if type(xpos) ~= "number" or type(ypos) ~= "number" then
        error_msg = ("coords %q,%q not numbers"):format(tostring(xpos), tostring(ypos))
    end
    if error_msg ~= nil then return nil, error_msg end

    local result = {label, {xpos, ypos}}
    if #coords == 3 then
        local wpos = coords[3]
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

    if type(entry.hover) == "string" then
        result.hover = entry.hover
    end

    return result, nil
end

--[[ True if the two POIs go to the same place
-- world=nil will treat x and y as absolute coordinates
--]]
function _is_same_location(entry1, entry2)
    local ex, ey, ew = unpack(entry1[2])
    local nx, ny, nw = unpack(entry2[2])
    if ew == nil then
        ex, ey, ew = pos_abs_to_rel(ex, ey)
    end
    if nw == nil then
        nx, ny, nw = pos_abs_to_rel(nx, ny)
    end
    return ex == nx and ey == ny and ew == nw
end

--[[ True if the given POI duplicates another POI ]]
function _is_duplicate_entry(entries, new_entry)
    for _, entry in ipairs(entries) do
        if entry.l then
            local res, dupe = _is_duplicate_entry(entry.l, new_entry)
            if res then return res, dupe end
        elseif _is_same_location(entry, new_entry) then
            return true, entry
        end
    end
    return false, nil
end

--[[ Decompose absolute [x, y] into [x, y, world offset] ]]
function pos_abs_to_rel(px, py)
    local pw, mx = check_parallel_pos(px)
    return mx, py, pw
end

--[[ Compose [x, y, world offset] into absolute [x, y] ]]
function pos_rel_to_abs(px, py, world)
    local x_adj = get_world_width() * world
    return px + x_adj, py
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
-- Returns status:false, error_message:nil if entry was already added.
--]]
function add_places_entry(entry)
    local entries = _get_places()
    local new_entry, error_msg = _create_poi(entry)
    if new_entry ~= nil then
        local duplicates, duplicate = _is_duplicate_entry(entries, new_entry)
        if duplicates then
            local e1str = _entry_to_string(new_entry)
            local e2str = _entry_to_string(duplicate)
            if e1str ~= e2str then
                return false, ("entry %s duplicates %s"):format(e1str, e2str)
            end
            return false, nil -- duplicates itself
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
function add_poi(name, x, y, world, hover)
    local coord = {x, y}
    if world then coord = {x, y, world} end
    local new_poi = {name, coord}
    if hover and type(hover) == "string" then
        new_poi.hover = hover
    end
    local result, error_msg = add_places_entry(new_poi)
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
function add_grouped_poi(group, name, x, y, world, hover)
    local coord = {x, y}
    if world then coord = {x, y, world} end
    local new_poi = {name, coord, group=group}
    if hover and type(hover) == "string" then
        new_poi.hover = hover
    end
    local result, error_msg = add_places_entry(new_poi)
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
