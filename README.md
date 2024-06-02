# Waypoints & Teleport

This mod provides numerous teleport destinations and the ability to add your own.

<strong>BEWARE SPOILERS</strong>. You have been warned. This mod makes <strong>no attempt whatsoever</strong> to protect you from things you don't know.

Comes pre-built with numerous predefined destinations, including the primary orbs, all bosses, and the holy mountains.

## Dependencies

This mod requires _Noita-Dear-ImGui_, which _must_ be above this mod in the load order. This mod can be downloaded via the following link: [https://github.com/dextercd/Noita-Dear-ImGui/releases](Noita-Dear-ImGui). Download and extract the archive into your Noita/mods folder.

This mod leverages (but does not require) _Disable Mod Restrictions_, which you can find via the following link: [https://modworkshop.net/mod/38530](Disable Mod Restrictions). Download and extract the archive into your Noita/mods folder. Note that _Disable Mod Restrictions_ needs to be updated every time a new version of Noita is released.

## Installation

If you don't have _Noita-Dear-ImGui_, download it [https://github.com/dextercd/Noita-Dear-ImGui/releases](by clicking this link) and extract the archive into your Noita/mods folder.

Next, download this repository [https://github.com/Kaedenn/noita-teleport/archive/refs/heads/main.zip](by clicking this link) and extract the archive into your Noita/mods folder.

Because _Noita-Dear-ImGui_ is a mod with compiled code, it requires enabling the unsafe mods option. This is also why it's not available via the Steam workshop. Also, _Noita-Dear-ImGui_ needs to be placed _above_ this mod in the mod list so that it gets loaded before this mod.

# Custom Locations

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

## Custom Location API

The `mods/kae_waypoint/data/kae/poi.lua` file exports a few functions for adding (or removing) custom locations.

For both `add` functions, `x` and `y` must be numbers. `world`, if specified, must be a number with `0` denoting the center world, positive numbers denoting East worlds, and negative numbers denoting West worlds.

<details>
<summary><code>add_poi(name, x, y, world=nil) -&gt; boolean, error_message:string</code> - Add a single item to the <code>Places</code> menu</summary>

* <code>name</code> type <code>string</code> or <code>Label</code>: POI display name; see _Labels_ below for structure.
* <code>x</code> type <code>number</code>: X pixel location
* <code>y</code> type <code>number</code>: Y pixel location
* <code>world</code> type <code>number</code>: World number for world-relative locations; optional

Returns `true, nil` on success.

Returns `false, error_message:string` on failure if the POI is invalid (parameters have incorrect types) or if the teleport destination duplicates an existing location.

</details>

<!-- *********************************************************************** -->

<details>
<summary><code>add_grouped_poi(group, name, x, y, world=nil) -&gt; boolean, error_message:string</code> - Add a grouped item to the <code>Places</code> menu</summary>

* <code>group</code> type <code>string</code>: Group name; menu display text
* <code>name</code> type <code>string</code> or <code>Label</code>: POI display name; see _Labels_ below for structure.
* <code>x</code> type <code>number</code>: X pixel location
* <code>y</code> type <code>number</code>: Y pixel location
* <code>world</code> type <code>number</code>: World number for world-relative locations; optional

Returns `true, nil` on success.

Returns `false, error_message:string` on failure if the POI is invalid (parameters have incorrect types) or if the teleport destination duplicates an existing location.

</details>

<!-- *********************************************************************** -->

<details>
<summary><code>remove_poi(name) -&gt; boolean</code> - Remove teleport destination(s) by name</summary>

* <code>name</code> type <code>string</code> or <code>Label</code>: POI display name; see _Labels_ below for structure.

Returns `true` if the operation actually removed one or more locations, `false` otherwise.

</details>

<!-- *********************************************************************** -->

<details>
<summary><code>remove_poi_group(group) -&gt; boolean</code> - Remove a teleport destination group</summary>

* <code>group</code> type <code>string</code>: Group name; menu display text

Returns `true` if the operation actually removed one or more locations, `false` otherwise.

</details>

<!-- *********************************************************************** -->

<details>
<summary><code>remove_poi_at(x, y, world) -&gt; boolean</code> - Remove a teleport destination by location</summary>

This function does not interpret between relative (world ~= 0) and absolute (world = nil) coordinates. Passing `nil` for `world` removes all teleport destinations with the given X and Y location, regardless of the world value.

* <code>x</code> type <code>number</code>: X pixel location
* <code>y</code> type <code>number</code>: Y pixel location
* <code>world</code> type <code>number</code>: World number for world-relative locations; optional

Returns `true` if the operation actually removed one or more locations, `false` otherwise.

</details>

<!-- *********************************************************************** -->

<details>
</summary><code>force_places_update()</code> - Force a UI refresh</summary>

This function forces a refresh of the entire UI and a recalculation of all teleport destinations.

</details>

## Labels

The `name` parameters to `add_poi` and `add_grouped_poi` accept both `string`s and `table`s to facilitate localization. Examples:

```lua
add_poi("My $biome_coalmine place", x, y)
add_poi({"$biome_winter"}, x, y)
add_poi({"$biome_west", {"$biome_winter"}}, x, y)
```

# Planned features
* GUI fallback if _Noita-Dear-ImGui_ isn't installed or isn't available (help wanted!).
* Indication whether or not the Cauldron contains void liquid if generated that day. Note that this won't necessarily mean the Cauldron _will_ contain void liquid if the chunk was generated on a prior day. See `utility/get_cauldron_bit.py`.

