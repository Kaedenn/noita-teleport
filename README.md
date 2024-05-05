# Waypoints & Teleport

This mod provides numerous teleport destinations.

Comes pre-built with numerous predefined destinations, including all orbs, all bosses, and the holy mountains.

# Dependencies

This mod requires _Noita-Dear-ImGui_, which _must_ be above this mod in the load order. This mod can be downloaded via the following link: [https://github.com/dextercd/Noita-Dear-ImGui/releases](Noita-Dear-ImGui). Download and extract the archive into your Noita/mods folder.

This mod leverages (but does not require) _Disable Mod Restrictions_, which you can find via the following link: [https://modworkshop.net/mod/38530](Disable Mod Restrictions). Download and extract the archive into your Noita/mods folder. Note that _Disable Mod Restrictions_ needs to be updated every time a new version of Noita is released.

# Installation

If you don't have _Noita-Dear-ImGui_, download it [https://github.com/dextercd/Noita-Dear-ImGui/releases](by clicking this link) and extract the archive into your Noita/mods folder.

Next, download this repository [https://github.com/Kaedenn/noita-teleport/archive/refs/heads/main.zip](by clicking this link) and extract the archive into your Noita/mods folder.

Because _Noita-Dear-ImGui_ is a mod with compiled code, it requires enabling the unsafe mods option. This is also why it's not available via the Steam workshop. Also, _Noita-Dear-ImGui_ needs to be placed _above_ this mod in the mod list so that it gets loaded before this mod.

# Planned features
* Custom locations (see below)
* GUI fallback if _Noita-Dear-ImGui_ isn't installed or isn't available (help wanted!).

# Custom locations

Mods can add their own custom teleport locations by leveraging the public API. Here's an example:

```lua
function OnWorldInitialized()
    dofile_once("mods/kae_waypoint/data/kae/poi.lua")
    add_poi("My Special Location", 1000, 2000)

    add_grouped_poi("My Locations", "Location One", 2000, 2000)
    add_grouped_poi("My Locations", "Location Two", 2000, 4000)
    add_grouped_poi("My Locations", "Location Three", 2000, 4000, 1) -- East 1
end
```

## Custom location API

The `mods/kae_waypoint/data/kae/poi.lua` file exports a few functions for adding (or removing) custom locations.

For both `add` functions, `x` and `y` must be numbers. `world`, if specified, must be a number with `0` denoting the center world, positive numbers denoting East worlds, and negative numbers denoting West worlds.

* `add_poi(name, x, y, world=nil) -> boolean`
  Add a single item to the `Places` menu. Returns `true` on success, `false` on error or if a location with the same target location already exists.
* `add_grouped_poi(group, x, y, world=nil) -> boolean`
  Add a grouped item to the `Places` menu. Returns `true` on success, `false` on error or if a location with the same target location already exists.
* `remove_poi(name) -> boolean`
  Remove all top-level entries having the given name. Returns `true` if at least one such entry was found, `false` otherwise.
* `remove_poi_group(group) -> boolean`
  Remove all entries belonging to the named group. Returns `true` if at least one such entry was found, `false` otherwise.


