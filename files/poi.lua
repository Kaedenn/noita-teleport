-- Coordinates to and supporting functions for the orbs, bosses, and
-- points of interest.

-- TODO:
-- Provide hover feedback if an eye location is inside cursed rock
-- Provide eye platform locations

--[[ Extra locations:
-- Eye Platform (Sky) 5933 -4825
-- Eye Platform (Power Plant) 13056 10023
-- Hell Shop (Mimicium Temple copy?) -1500 43600 (verify NG+)
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_waypoint/files/temple.lua")
dofile_once("mods/kae_waypoint/files/orbs.lua")

BOSSES = {
    {"$animal_boss_alchemist (High Alchemist)", {-4850, 860}},
    {"$animal_boss_limbs (Pyramid Boss)", {10000, -820}},
    {"$animal_boss_pit (Connoisseur of Wands)", {4350, 880}},
    {"$animal_boss_ghost (The Forgotten)", {-11500, 13150}},
    {"$animal_fish_giga (Lake Guardian)", {-14000, 9900}},
    {"$animal_gate_monster_a (Gate Guardian)", {2800, 11550}},
    {"$animal_boss_centipede", {3550, 13000}},
    {"$animal_boss_wizard (Master of Masters)", {12550, 15200}},
    {"$animal_boss_robot (Mecha Kolmi)", {14080, 10900}},
    {"$animal_boss_dragon (Dragon)", {2200, 7450}},
    {"$animal_maggot_tiny (Slime Maggot; Tiny)", {14900, 18450}},
    {"$animal_boss_meat (Meat Boss)", {6700, 8500}},
    {"$animal_boss_sky (Rock Boss)", {7380, -4550}},
}

PLACES = setmetatable({
    {"Spawn", {227, -80}},
    {"Mountain Altar", {780, -1150}},
    {"$biome_lake", l = {
        {"Island", {-14211, 209}},
        {"Fishing Hut", {-12500, 200}},
    }},
    {"Perk Removal Altar",
        {14196, 7551},
        refine_fn = function(self)
            local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
            if newgame_n ~= 0 then
                return {-11520, 13100}
            end
            return self
        end},
    {"Celestial Bodies", l = {
        {"Moon", {290, -25500}},
        {"Dark Moon", {350, 37500}},
        {"$perk_radar_moon", {16130, 3330}},
    }},
    {"Temples", l = {
        {"$biome_watchtower", {14075, -960}},
        {"$biome_barren", {-5380, -5240}},          -- Barren Temple
        {"$biome_boss_sky", {7380, -5050}},         -- Kivi Temple
        {"$biome_darkness", {2600, -4670}},         -- Ominous Temple
        {"$biome_potion_mimics", {-1820, -4640}},   -- Henkeva Temple
    }},
    {"$animal_friend Caves", l = { -- see update_toveri_cave
        {"Upper West", {-10500, 4350}},   -- fspot 4
        {"Lower West", {-10900, 11550}},  -- fspot 5
        {"Upper Center", {-4850, 4850}},  -- fspot 3
        {"Lower Center", {-4850, 13000}}, -- fspot 6
        {"Upper East", {3340, 5900}},     -- fspot 1
        {"Lower East", {4350, 10000}},    -- fspot 2
    }},
    {"Spells", l = {
        {"$action_touch_piss", {9050, -1815}},      -- Outhouse
        {"$action_all_spells", {-4830, 15009}},     -- End of Everything
        {"$action_rainbow_trail", {-14000, -2851}},
    }},
    {"The Cauldron", {3845, 5435},
        label_fn = function() -- TODO: check cauldron bit
            return "The Cauldron"
        end,
        hover = "This only appears if you have Disable Mod Restrictions active"},
    {"Karl's Racetrack", {3300, 2350}},
    {"Avarice Diamond", {9400, 4300},
        hover = "At the top of The $biome_tower"},
    {"Portals & Portal Rooms", l = {
        {"Portal Room", {3836, 7540},
            hover = "Portals are active after defeating $animal_fish_giga"},
        {"Meditation Cube Room", {-4300, 2300},
            hover = "Secret room accessible from $biome_excavationsite"},
        {"Buried Diamond Room", {3900, 4400},
            hover = "Secret room accessible from $biome_snowcave"},
        {"Eye Room", {-3800, 5400},
            hover = "Secret room accessible from $biome_snowcastle"},
        {"Tower Portal", {-4330, 10850},
            hover = "Portal leading to The $biome_tower"},
    }},
    {"Items", l = {
        {"$item_evil_eye (Evil Eye)", {-2434, -207}},
        {"$item_musicstone (Music Stone)", {-3330, 3330}},
        {"$item_gourd Cave", {-16125, -6300}},
    }},
    {"Essences", l = {
        {"$item_essence_air", {-13055, -5360}},
        {"$item_essence_alcohol", {-14080, 13570}},
        {"$item_essence_fire", {-14060, 375}},
        {"$item_essence_greed", {-1375, -420}},
        {"$item_essence_laser", {16130, -1780}}, -- Earth
        {"$item_essence_water", {-5375, 16650}},
    }},
    {"$item_essence_stone", l = { -- Essence Eaters
        {"$biome_winter", {-6880, -170}},
        {"$biome_desert", {12569, 15}},
        {{"$biome_east", {"$biome_winter"}}, {-43235, -170}},
        {{"$biome_east", {"$biome_desert"}}, {-23783, 15}},
        {{"$biome_west", {"$biome_winter"}}, {29459, -170}},
        {{"$biome_west", {"$biome_desert"}}, {48921, 15}},
    }},
    {"Music Machines", l = {
        {"Snow", {-12180, -420}},   -- music_machine_02
        {"Desert", {14700, -80}},   -- music_machine_00
        {"Tree", {-1905, -1420}},   -- music_machine_01
        {"Lake", {2800, 260}},      -- music_machine_03
    }},
    {"Chests", l = {
        {"$item_chest_light", {11520, -4875}},
        {"$item_chest_dark", {3875, 15600}},
    }},
    {"Shops", l = {
        {"Hell", {-3000, 28000}},
        {"Hell +1", {-3000, 52600}},        -- Y=Y+246000
        {"Hell +2", {-3000, 77200}},        -- Y=Y+246000
        {"Hell (Mimic)", {-1750, 19400}},   -- Verify
        {"Hell (Kivi)", {2775, 19550}},     -- Verify
        {"Hell (small)", {-3310, 35800}},   -- Verify
        {"Hell (mini)", {130, 24727}},      -- Verify
        {"Sky", {-3300, -21000}},           -- Verify
        {"Sky (Mimic)", {-1750, -29730}},   -- Verify
        {"Sky (Kivi)", {2775, -29570}},     -- Verify
        {"Sky (small)", {3310, -13300}},    -- Verify
    }},
    {"Special Wands", l = {
        {"$item_wand_experimental_1 (Gun)", {16130, 10000}},
        {"$item_ocarina (Ocarina)", {-10000, -6475}},
        {"$item_kantele", {-1630, -750}},
    }},
    {"Biomes", l = {
        {"Western $biome_gold", {-14080, 16640}}, -- biome -27.5 -32.5
        {"Eastern $biome_gold", {15100, -3200}},
        {"Infinite $biome_robobase", {-16640, 16896}}, -- biome -32.5 33
    }},
    {"Eye Glyphs", l = { },
        hover = "These only appear if you have Disable Mod Restrictions active"},

    --[[ Example custom waypoint with filter and update functions ]]
    {"Custom Waypoint (Example)",
        {-1, -1}, -- default position
        filter_fn = function(self) return false end, -- never display
        update_fn = function(self) return 0, 0, 0 end, -- always origin
        hover = "This text will appear if you hover over the menu item",
    },
}, {
    __index = function(tbl, key)
        if type(key) == "number" then
            return rawget(tbl, key)
        end
        if type(key) == "string" then
            for _, entry in ipairs(tbl) do
                local label = entry[1]
                if key == label then
                    return entry
                end
            end
            return nil
        end
    end
})

--[[ Private functions not intended for modders to use ]]

--[[ Where is Toveri? Taken from data/scripts/biomes/friend_#.lua ]]
function deduce_toveri_cave()
    SetRandomSeed(24, 32)
    local cave_idx = Random(1, 6)
    return cave_idx
end

--[[ Update the PLACES table with Toveri's location ]]
function update_toveri_cave(cave_idx) -- returns {x, y}
    if cave_idx < 1 or cave_idx > 6 then
        error(("invalid cave index %d; not between 1..6"):format(cave_idx))
    end
    local menu_assoc = {5, 6, 3, 1, 2, 4}
    local menu_idx = menu_assoc[cave_idx]
    for _, entry in ipairs(PLACES) do
        local key = entry[1]
        if key == "$animal_friend Caves" then
            local item = entry.l[menu_idx]
            item[1] = item[1] .. " [!]"
            item.hover = "This is where $animal_friend is currently"
            return item[2]
        end
    end
    error("Failed to find '$animal_friend Caves' entry")
end

--[[ Update the locations of the Eye Glyphs ]]
function update_eye_locations()
    dofile("mods/kae_waypoint/files/eyes.lua")
    PLACES["Eye Glyphs"].l = {}
    for idx, entry in ipairs(get_eye_locations(nil)) do
        local eyex, eyey = entry[2], entry[3]
        local eyenum = math.floor((idx+1)/2)
        local label = ("%s %d [%d %d]"):format(entry[1], eyenum, eyex, eyey)
        local new_poi = {label, {eyex, eyey}}
        table.insert(PLACES["Eye Glyphs"].l, new_poi)
    end
end

--[[ Public API for mods wishing to add their own waypoints ]]

function create_poi(args)
    local poi_label = args[1]
    local poi_coord = args[2] or {nil, nil}
    local poi = {poi_label, poi_coord}
    if args.label_fn and type(args.label_fn) == "function" then
        poi.label_fn = args.label_fn
    end
    if args.filter_fn and type(args.filter_fn) == "function" then
        poi.filter_fn = args.filter_fn
    end
    if args.refine_fn and type(args.refine_fn) == "function" then
        poi.refine_fn = args.refine_fn
    end
    if args.group and type(args.group) == "string" then
        poi.group = args.group
    end
    if args.hover and type(args.hover) == "string" then
        poi.hover = args.hover
    end
    return poi
end

--[[ True if the given POI looks good ]]
function is_valid_poi(entry)
    if type(entry) ~= "table" then return false end
    if #entry ~= 2 then return false end
    local ename, epos = unpack(entry)
    local ntype, ptype = type(ename), type(epos)
    if ntype ~= "string" and ntype ~= "table" then return false end
    if ptype ~= "table" then return false end
    if #epos ~= 2 and #epos ~= 3 then return false end
    if #epos == 0 then
        if not entry.filter_fn and not entry.refine_fn then
            return false
        end
    end
    return true
end

--[[ True if the two entries go to the same place ]]
function compare_poi(entry1, entry2)
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

--[[ True if the entry duplicates an existing one ]]
function is_duplicate_poi(entry)
    for _, place in ipairs(PLACES) do
        if place.l then
            for _, place2 in ipairs(place.l) do
                if compare_poi(place2, entry) then
                    return true
                end
            end
        elseif compare_poi(place, entry) then
            return true
        end
    end
    return false
end

--[[ Add a boss to the end of the bosses list ]]
function add_boss_entry(label, x, y)
    table.insert(BOSSES, create_poi{label, {x, y}})
end

--[[ Add a place of interest to the end of the POI list ]]
function add_places_entry(label, x, y)
    table.insert(PLACES, create_poi{label, {x, y}})
end

--[[ Add a place of interest to the end of a POI group entry ]]
function append_places_entry(group, label, x, y)
    local poi = create_poi{label, x, y}
    local place_entry = nil
    for _, entry in ipairs(PLACES) do
        if entry[1] == group then
            place_entry = entry
            break
        end
    end
    if not place_entry then
        -- Didn't find the mentioned place; add a new one
        table.insert(PLACES, {group, l={poi}})
    elseif not place_entry.l then
        -- It exists, but isn't a list; make it one
        local old_poi = {place_entry[1], place_entry[2]}
        -- Copy over any custom stuff
        for key, val in pairs(place_entry) do old_poi[key] = val end
        place_entry.l = {old_poi, poi}
        table.remove(place_entry, 2) -- remove old coord
    else
        table.insert(place_entry.l, poi)
    end
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
