--[[ Functions supporting biomes ]]

function get_biome_name(biomex, biomey)
    local biome = BiomeMapGetName(biomex, biomey)
    local name = nil
    if biome and biome ~= "" and biome ~= "_EMPTY_" then
        name = GameTextGet(biome)
        if biome == "$biome_holymountain" then
            local next_biome = BiomeMapGetName(biomex, biomey+512)
            if next_biome ~= "_EMPTY_" then
                name = name .. " above " .. GameTextGet(next_biome)
            end
        end
    end
    return name
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
