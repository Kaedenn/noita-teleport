--[[ Internationaliztion routines ]]

dofile_once("mods/kae_waypoint/files/utility.lua")

--[[ Localize an item

localize("Current biome: $biome_wandcave")
localize("$biome_wandcave")
localize("Fixed text")

localize({"$biome_west", "Point of Interest"})
localize({"$biome_west", {"$biome_wandcave"}})

localize({"text", "arg"})
--]]
function _localize(item, titlecase)
    -- Shorthand for localizing an entire string
    local result
    if type(item) == "string" then
        result = item:gsub("$[a-z0-9_]*", GameTextGet)
    elseif type(item) == "table" then
        local value = item[1]
        local arg1 = item[2] or ""
        local arg2 = item[3] or ""
        if type(arg1) == "table" then arg1 = _localize(arg1, titlecase) end
        if type(arg2) == "table" then arg2 = _localize(arg2, titlecase) end
        result = GameTextGet(value, arg1, arg2)
    else
        error(("Cannot localize %s"):format(tostring(item)))
    end
    if titlecase then return title(result) end
    return result
end

--[[ Localize an array of values

localize_multi({"Current biome: ", {"$biome_wandcave"}})
localize_multi({"Biome: ", {"$biome_west", {"$biome_wandcave"}}})

localize_multi({item1, item2, ..., itemN}) where
    item is string -> appended as-is
    item is table -> localized and then appended
    item is other -> converted to string and then appended
--]]
function _localize_multi(array, titlecase)
    local results = {}
    for _, item in ipairs(array) do
        if type(item) == "table" then
            table.insert(results, _localize(item, titlecase))
        elseif type(item) == "string" then
            if titlecase then item = title(item) end
            table.insert(results, item)
        else
            table.insert(results, tostring(item))
        end
    end

    local result = ""
    for _, value in ipairs(results) do
        result = result .. value
    end
    return result
end

return {
    localize = _localize,
    localize_multi = _localize_multi,
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
