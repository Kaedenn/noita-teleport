--[[ Provide mods the ability to add custom places ]]

function _encode_places(entries)
    local smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")
    return smallfolk.dumps(entries)
end

function _decode_places(entries)
    local smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")
    return smallfolk.loads(entries)
end

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

function _save_places(places)
    local key = "kae_waypoint._places"
    local data = _encode_places(places)
    ModSettingSetNextValue(key, data, false)
end

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
    if type(entry.filter_fn) == "function" then
        result.filter_fn = entry.filter_fn
    end
    if type(entry.refine_fn) == "function" then
        result.refine_fn = entry.refine_fn
    end
    return result, nil
end

--[[
-- Add a new place to the PLACES table.
--
-- add_places_entry({"My Place", {100, 100}})
-- add_places_entry({"My Place", {100, 100, 1}})
-- add_places_entry({"My Place", {100, 100}, group="My Places"})
-- add_places_entry({"My Place", {100, 100},
--      filter_fn = function(self) return true end,
--      refine_fn = function(self) return 200, 200 end})
--
-- Returns status:true, error_message:nil on success.
-- Returns status:false, error_message:string on error.
--]]
function add_places_entry(entry)
    local entries = _get_places()
    local new_entry, error_msg = _create_poi(entry)
    if new_entry ~= nil then
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
    local result, error_msg = add_places_entry({
        name, coord, group=group
    })
    return result, error_msg
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
