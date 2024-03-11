--[[ Supporting functions ]]

function title(str)
  local result = str:gsub("^[a-z]", string.upper)
  return result:gsub("[ \t][a-z]+", function(piece)
    if piece:len() > 3 then -- +1 for non-ascii character
      return piece:gsub("^.[a-z]", string.upper)
    end
    return piece
  end)
end
