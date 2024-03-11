-- Coordinates to and supporting functions for the orbs, bosses, and
-- poits of interest.
--
-- Currently does not support NG+. This is planned, though.
--

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_waypoint/files/temple.lua")
dofile_once("mods/kae_waypoint/files/orbs.lua")

ORBS = {
    {"Toth ($biome_pyramid)", {10000, -1170}},
    {"Vol I (Mountain Altar)", {780, -1080}},
    {"Vol II ($biome_vault_frozen)", {-9950, 2900}},
    {"Vol III ($biome_lavacave)", {3480, 1890}},
    {"Vol IV ($biome_sandcave)", {10000, 2920}},
    {"Vol V ($biome_wandcave)", {-4350, 3950}},
    {"Vol VI ($biome_rainforest_dark)", {-3820, 10100}},
    {"Vol VII ($biome_lava)", {4350, 880}},
    {"Vol VIII ($biome_boss_victoryroom (Hell))", {-452, 16200}},
    {"Vol IX ($biome_winter_caves)", {-9000, 14700}},
    {"Vol X ($biome_wizardcave)", {10500, 16200}},
}

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
}

PLACES = {
    {"Spawn", {227, -80}},
    {"Mountain Altar", {780, -1150}},
    {"$biome_lake", l = {
        {"Island", {-14211, 209}},
        {"Fishing Hut", {-12500, 200}},
    }},
    {"Perk Removal Altar", {14196, 7551}}, -- FIXME: NG+ -11520, 13100
    {"Celestial Bodies", l = {
        {"Moon", {290, -25500}},
        {"Dark Moon", {350, 37500}},
        {"$perk_radar_moon", {16130, 3330}},
    }},
    {"$animal_friend Caves", l = { -- see update_toveri_cave
        {"Upper West", {-10500, 4350}},   -- fspot 4 lspot 1
        {"Lower West", {-10900, 11550}},  -- fspot 5 lspot 2
        {"Upper Center", {-4850, 4850}},  -- fspot 3 lspot 3
        {"Lower Center", {-4850, 13000}}, -- fspot 6 lspot 4
        {"Upper East", {3340, 5900}},     -- fspot 1 lspot 5
        {"Lower East", {4350, 10000}},    -- fspot 2 lspot 6
    }},
    {"Spells", l = {
        {"$action_all_spells", {-4830, 15009}},
        {"$action_rainbow_trail", {-14000, -2851}},
    }},
    {"The Cauldron", {3845, 5435}},
    {"Karl's Racetrack", {3300, 2350}},
    {"Avarice Diamond", {9400, 4300}},
    {"Portals & Portal Rooms", l = {
        {"Portal Room", {3836, 7540}},
        {"Tower Portal", {-4330, 10850}},
        {"Buried Diamond Room", {3900, 4400}},
        {"Eye Room", {-3800, 5400}},
        {"Meditation Cube Room", {-4300, 2300}},
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
        {"Snow", {-12180, -420}},   -- music_machine_02 ??
        {"Desert", {14700, -80}},   -- music_machine_00
        {"Tree", {-1905, -1420}},   -- music_machine_01
        {"Lake", {2800, 260}},      -- music_machine_03
    }},
    {"Chests", l = {
        {"$item_chest_light", {11520, -4875}},
        {"$item_chest_dark", {3875, 15600}},
    }},
    {"Shops", l = {
        {"Sky", {0, -13954}}, -- Verify
        {"Hell", {-3000, 28000}},
        {"Hell 2", {-3000, 52600}}, -- Y2=Y1+246000
        {"Hell 3", {-3000, 77200}}, -- Y3=Y2+246000
    }},
    {"$mat_gold", l = {
        {"Western $biome_gold", {-20700, -3200}},
        {"Eastern $biome_gold", {15100, -3200}},
    }},
    {"Special Wands", l = {
        {"$item_wand_experimental_1 (Gun)", {16130, 10000}},
        {"$item_ocarina (Ocarina)", {-10000, -6475}},
        {"$item_kantele", {-1630, -750}},
    }},
}

--[[ Update the orb positions for NG+ ]]
function update_orbs_ngplus()
    local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
    local orb_map = orb_map_get() -- From utilities.lua
    for idx, entry in ipairs(orb_map) do
        local orb_name = ("Orb %d"):format(idx)
        local world_x = entry[1] * 512 + 256
        local world_y = entry[2] * 512 + 256
    end
end

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
            local val = entry.l
            val[menu_idx][1] = val[menu_idx][1] .. " [!]"
            return val[menu_idx][2]
        end
    end
    error("Failed to find '$animal_friend Caves' entry")
end

return {
    ORBS = ORBS,
    BOSSES = BOSSES,
    PLACES = PLACES,
    Orbs = Orbs,
    init_orb_list = init_orb_list,
    Temples = Temples,
    init_temple_list = init_temple_list,
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
