# Waypoints & Teleport

This mod provides numerous teleport destinations.

Comes prebuilt with numerous predefined destinations, including all orbs, all bosses, and the holy mountains.

# Dependencies

This mod requires `Noita-Dear-ImGui`, which _must_ be above this mod in the load order. This mod can be found by searching the Noita Mod Workshop (not Steam Workshop!) for "Noita-Dear-ImGui". It's also downloadable via the Noita discord.

# Installation

Download this repository into your Noita/mods folder.

# Custom locations

Mods can define their own custom teleport locations by appending code to the `mods/kae_teleport/files/poi.lua` file.

The structure and API are still being designed. Stay tuned!

```lua

-- Simple addition for static coordinates
add_boss_entry("My New Boss", {2000, 4000})
add_places_entry("My New Place", {2000, 4000})
append_places_entry("Portals", "My New Portal", {2000, 4000})

-- Directly, allowing for custom behavior:
table.insert(PLACES, {
  -- item[1] is the name (label) of your waypoint
  "My Custom Waypoint",
  -- item[2] is the location, either {x, y} or {x, y, world}
  {2000, 4000, 0},

  --[[ Filter: return false to hide this waypoint.
  -- Called when building the menu. ]]
  filter_fn = function(self)
    local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
    if newgame_n == 0 then
      return true -- only display in New Game, not NG+
    end
    return false
  end,

  --[[ Refine: update the position to a more accurate one.
  -- Return nil, nil to use the original location.
  -- Called when invoking the teleport. ]]
  refine_fn = function(self)
    local pos = self[2]
    return {pos[1], pos[2] - 512} -- go up by one chunk
  end,
})
```

# TODO

1. Document i18n support for labels
2. Add proper undo/redo support

