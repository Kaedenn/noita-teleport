--[[ Determine the teleport locations of the Eye Glyphs
--
-- Requires Diable Mod Restrictions.
--
--]]

BIOME_CELL_SIZE = 512.0

--[[ Possible spawn locations in the New Game biome map ]]
local map_ng = {
  "1111111111100000000000000000000000000000000000000000000001000000000111",
  "1110111111111110000000000000000000000000000000000000000001001110000111",
  "1111111111111110000000000000000000000000000000000000000001001110000111",
  "1111111110111110000000000000000000000000000000000000011111101110000111",
  "1111111111111110000000000000000000000000000000000000011110101110000111",
  "1111111111111110000000000000000000000000000000000000011111111111111111",
  "1111111111100000000000000000000000000000000000000000000000000011111111",
  "1111111111100000000000000000000000000000100000000000000000000011011111",
  "1111111111100000000000000000000000000000100000000000000000000011111111",
  "1111111111100000000000000000000000000000100000000000000000000011111111",
  "1111111111100000000000000000000000000000100000000000000000000000000111",
  "1111111111100000000000000000000001001000100000000000000000000000001111",
  "1111111111100000000000000000000000001000100000000000000000000000001111",
  "1111111111100000000000000000000000010100100000000000000000000000001111",
  "1111111111100000000000000000011000000000100000000000000000000000001111",
  "1111111111100000000100011000000000000000000010000010000000100000001111",
  "1111111111110000000100011111111111111111000110000010000000100000001111",
  "1111111111110000000100001111000000000001000110000010000000100000001111",
  "1111111111110000000100001101100000000001100110000010000000100000001111",
  "1111111111110000000100001111111111111111110110000010000000100000001111",
  "1111111111111111111100001111010000000000000110000011111111100000000111",
  "1111111111111111111100001100000000000000111110000011111111100000001111",
  "1111111111111111000100001111110000000000110110000011100011100000001111",
  "1111111111111111000000001111111111111111111110000011100011100000001111",
  "1111111111111111100000011110111000000011111110000011100011100000001111",
  "1111111111111111000000000011111000000011111110000011100011100000001111",
  "1111111111111110000000010001111111111111111110000011100011100000001111",
  "1111111111111110000000011101110000000001111110000011100011100000001111",
  "1111111111111110000000011100000000000001111110000011100011100000001111",
  "1111111111111110000000001000010000000001111110000011100011100110001111",
  "1111111111111110000000001000011111111111111110000011100011100000001111",
  "1111111111111110000000001000000000000000111110000011100011100000001111",
  "1111111111111110000000001001100000000000111110000011111111100000001111",
  "1111111111111110000000001100100000000000111110000011111110100000000111",
  "1111111111111110000000001111111111111111111110000011111111100000001111",
  "1111111111111110000000001101100000000000111111100011111111100000001111",
  "1111111111111110000000001101100000000000000000000000000000000000001111",
  "1111111111111110000000001100000000000000111111100000000000000000001111",
  "1111111111111110000000001111100000000011111111100000000000000000001111",
  "1111111111110000000000011111111111111111111111111111100000100000001111",
  "1111111011111100000000011110000000000000110001111111100000110000001111",
  "1111111111111110000000111100000000000000000000000011100000111100001111",
  "1111111111111110000001111001111111111111111110111011100000011100001111",
  "1111111111111111111111110001100000000000111110111011100000001100001111",
  "0000000000000000000000000011100000000000110110111011100000111100001111",
  "1111101110111111111111111110000000000000100000000001110001111100001111",
  "1111001010011111111111110000000000000000100001111101111111111111111111",
  "1101011111011111111111111110000000000000001011111101111111111111111111"
}

local function mt127773_next(rand)
    local hi = math.floor(rand / 127773)
    local lo = rand - hi * 127773
    local temp_r = 16807 * lo - 2836 * hi
    if temp_r <= 0 then
        temp_r = temp_r + 0x7fffffff
    end
    return temp_r
end

local function get_pw_index(message_index)
    return message_index % 2 == 0 and 1 or -1
end

local function has_cave_background(x, y)
    local row = map_ng[y+1] or error(("y+1 %d > %d"):format(y+1, #map_ng))
    return row:sub(x+1, x+1) == "1"
end

local function convert_chunk_coords(x, y, pw_index)
    local biome_width, biome_height = BiomeMapGetSize()
    local xoffset = BIOME_CELL_SIZE * biome_width / 2
    local yoffset = BIOME_CELL_SIZE * 14
    local finalx = pw_index * BIOME_CELL_SIZE * biome_width + x * BIOME_CELL_SIZE - xoffset + 48.0
    local finaly = y * BIOME_CELL_SIZE - yoffset + 64.0
    return {finalx, finaly}
end

local function calculate_eye_message_positions(seed, current_pw)
    local world_chunk_length, world_chunk_height = BiomeMapGetSize()
    local positions = {}
    local rand = bit.bxor(seed, 0xe4bc7e0)
    if rand < 0 then
        rand = rand * -0.5
    end
    rand = mt127773_next(rand)
    local temp = rand

    for message_index = 0, 8 do
        local pw_index = get_pw_index(message_index)
        if current_pw ~= pw_index then
            goto continue
        end

        local found = false
        for attempts = 0, 999 do
            local y = mt127773_next(temp)
            -- 4.656612875e-10 is roughly 1/0x7fffffff
            local x = math.floor(y * 4.656612875e-10 * world_chunk_length)
            y = mt127773_next(y)
            temp = y -- Save the value for later
            y = math.floor(y * 4.656612875e-10 * world_chunk_height)

            if has_cave_background(x, y) then
                local coords = convert_chunk_coords(x, y, pw_index)
                table.insert(positions, coords)
                found = true
                break
            end
        end
        if not found then
            table.insert(positions, {nil, nil})
        end

        ::continue::
    end
    return positions
end

--[[ Determine the locations of the eye glyphs for the given (or current) seed.
--
-- Returns a table of the following three items:
--  "east" or "west"
--  x pixel location
--  y pixel location
--
-- Only works in New Game, not New Game+, as that requires a different map.
--]]
function get_eye_locations(seed)
    if not seed then
        seed = tonumber(StatsGetValue("world_seed"))
    end

    local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
    if newgame_n > 1 then
        return {}
    end
    local biome_width, biome_height = BiomeMapGetSize()
    local positions = calculate_eye_message_positions(seed, 1)
    local results = {}
    for idx, pos in ipairs(positions) do
        local xpos, ypos = pos[1], pos[2]
        if xpos == nil and ypos == nil then
            table.insert(results, {"invalid", 0, 0})
        else
            table.insert(results, {"east", pos[1], pos[2]})
            if idx <= 4 then
                local adjust = 2 * biome_width * BIOME_CELL_SIZE
                table.insert(results, {"west", pos[1] - adjust, pos[2]})
            end
        end
    end
    return results
end

--[[ Testing
if _G.lualib then
    local results
    if #arg > 0 then
        results = get_eye_locations(math.floor(tonumber(arg[1])))
    else
        print("Seed: ")
        results = get_eye_locations(math.floor(io.read("*n")))
    end
    for idx, entry in ipairs(results) do
        local world, xpos, ypos = entry[1], entry[2], entry[3]
        print(("%s %d = {%d, %d}"):format(world, idx, xpos, ypos))
    end

    os.exit()
end
]]

-- vim: set ts=4 sts=4 sw=4:
