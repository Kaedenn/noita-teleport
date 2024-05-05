--[[ Supporting functions ]]

--[[ Title-case a string ]]
function to_title(str)
  local result = str:gsub("^[a-z]", string.upper)
  return result:gsub("[ \t][a-z]+", function(piece)
    if piece:len() > 3 then -- +1 for non-ascii character
      return piece:gsub("^.[a-z]", string.upper)
    end
    return piece
  end)
end

--[[ Determine the RGB values for the given color ]]
function lookup_color(color)
    local color_table = {
        red = {1, 0, 0},
        green = {0, 1, 0},
        blue = {0, 0, 1},
        cyan = {0, 1, 1},
        magenta = {1, 0, 1},
        yellow = {1, 1, 0},
        white = {1, 1, 1},
        black = {0, 0, 0},

        red_light = {1, 0.5, 0.5},
        green_light = {0.5, 1, 0.5},
        blue_light = {0.5, 0.5, 1},
        cyan_light = {0.5, 1, 1},
        magenta_light = {1, 0.5, 1},
        yellow_light = {1, 1, 0.5},
        gray = {0.75, 0.75, 0.75},
    }
    if color_table[color] then
        return color_table[color]
    end
    return {1, 1, 1}
end
