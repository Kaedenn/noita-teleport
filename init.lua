--[[ Waypoints and Teleport
--
-- This mod provides numerous teleport destinations to things of interest:
--  Orbs (all 11 standard)
--  Bosses
--  Places of interest
--  Temples
--
-- Key features include:
--  Correct identification of Toveri's cave
--  Identification of collapsed temples (only works in NG)
--  Live tracking of player position
--
--]]

--[[ TODO:
-- History of warps for undo/redo
--
-- Allow waypoint destinations to define the following functions:
--  refine(target_x, target_y)
--  get_label()
--  on_teleport(...)
--
-- Allow teleporting by clicking on a biome map
--  BiomeMapConvertPixelFromUintToInt to get color, possibly?
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
KConf = dofile_once("mods/kae_waypoint/config.lua")
POI = dofile_once("mods/kae_waypoint/files/poi.lua")
I18N = dofile_once("mods/kae_waypoint/files/i18n.lua")
dofile_once("mods/kae_waypoint/files/utility.lua")

local imgui
local g_messages = {}
local g_force_update = true     -- trigger a POI recalculation
local g_toveri_updated = false  -- did we determine Toveri's location?
local g_teleport_now = false    -- don't just load the POI; teleport to it
local g_save_ng = 0             -- cached NG+ count

-- Inputs to the main GUI. Global so other functions can update them.
local input_x = 0
local input_y = 0
local input_world = 0
local input_relative = false

function add_msg(msg)
    table.insert(g_messages, 1, msg)
end

function add_last_msg(msg)
    if #g_messages > 0 and g_messages[#g_messages] ~= msg then
        add_msg(msg)
    end
end

function add_unique_msg(msg)
    for _, message in ipairs(g_messages) do
        if message == msg then
            return
        end
    end
    add_msg(msg)
end

function debug_msg(msg)
    if KConf.SETTINGS:get("debug") then
        add_msg("DEBUG: " .. msg)
    end
end

function on_error(arg)
    if arg ~= nil then
        GamePrint(tostring(arg))
        add_msg(arg)
    else
        GamePrint("on_error called with nil value!")
        add_msg("on_error called with nil value!")
    end
    if debug and debug.traceback then
        add_msg(debug.traceback())
    else
        add_msg("debug or debug.traceback unavailable")
    end
end

-- value == nil ? nilvalue : value
function nil_or(value, nilvalue)
    if value == nil then
        return nilvalue
    end
    return value
end

-- The world size can vary between NG and NG+
function get_world_width()
    return BiomeMapGetSize() * 512
end

-- Get the absolute position of the player
function get_player_pos(player)
    local px, py = EntityGetTransform(player)
    return px, py
end

-- Decompose absolute [x, y] into [x, y, world offset]
function pos_abs_to_rel(px, py)
    local pw, mx = check_parallel_pos(px)
    return mx, py, pw
end

-- Compose [x, y, world offset] into absolute [x, y]
function pos_rel_to_abs(px, py, world)
    local x_adj = get_world_width() * world
    return px + x_adj, py
end

-- Player coordinates prior to the warp, for optional return later
local save_x, save_y, save_world = nil, nil, nil

-- Warp the player to the given coordinates
function warp_to(args)
    if #args == 0 then
        add_msg("ERROR: warp_to() missing required argument")
        return nil
    end

    local player = args[1] or error("player object is nil")
    local abs_x, abs_y = get_player_pos(player)
    debug_msg(("abs_x=%q abs_y=%q for player=%q"):format(abs_x, abs_y, player))

    local plr_x, plr_y, plr_world = pos_abs_to_rel(abs_x, abs_y)

    local arg_x, arg_y, arg_world
    if args.add then
        arg_x = plr_x + nil_or(args.x, 0)
        arg_y = plr_y + nil_or(args.y, 0)
        arg_world = plr_world + nil_or(args.world, 0)
    else
        arg_x = nil_or(args.x, plr_x)
        arg_y = nil_or(args.y, plr_y)
        arg_world = nil_or(args.world, plr_world)
    end

    local final_x, final_y = pos_rel_to_abs(arg_x, arg_y, arg_world)
    debug_msg(("Warp to [%.02f, %.02f] in PW %d (%.02f, %.02f)"):format(
        arg_x, arg_y,
        arg_world,
        final_x, final_y))

    if not args.returning then
        save_x, save_y, save_world = plr_x, plr_y, plr_world
        debug_msg("Saved current player position")
    end

    EntitySetTransform(player, final_x, final_y)

    debug_msg(("Warped to %0.2f, %0.2f"):format(final_x, final_y))

    GamePrint(("Warped to %0.2f, %0.2f, world %d"):format(
        arg_x, arg_y, arg_world))

end

function load_waypoint(item)
    local name = item[1]
    local pos = item[2] or {}
    if #pos == 0 then return end -- don't load an empty waypoint

    local target_x = pos[1] or pos.x or nil
    local target_y = pos[2] or pos.y or nil
    local target_world = pos[3] or pos.world or 0
    if target_x == nil or target_y == nil then
        add_msg(("Invalid waypoint %s"):format(name))
        return
    end

    input_x = target_x
    input_y = target_y
    input_world = target_world
    if KConf.SETTINGS:get("quick_teleport") then
        g_teleport_now = true
    end
end

function save_player_pos(player)
    local abs_x, abs_y = get_player_pos(player)
    local plr_x, plr_y, plr_world = pos_abs_to_rel(abs_x, abs_y)

    -- TODO
end

function _add_menu_item(item)
    local label_raw = item[1] or error(("malformed value %s"):format(item))
    local label = I18N.localize(label_raw, true)
    if item.l ~= nil then
        -- It's a nested item
        if imgui.BeginMenu(label) then
            for _, sub_item in pairs(item.l) do
                _add_menu_item(sub_item)
            end
            imgui.EndMenu()
        end
    else
        -- Nested items can't have coordinates of their own
        local pos = item[2] or {}
        if #pos < 2 then
            label = label .. " [TODO]"
        end
        if imgui.MenuItem(label) then
            load_waypoint({label, pos})
            add_msg(("Loaded waypoint %q"):format(label))
        end
    end
end

function _build_menu_bar_gui()
    if imgui.BeginMenuBar() then
        local mstr
        if imgui.BeginMenu("Actions") then
            if imgui.MenuItem("Refresh") then
                g_force_update = true
            end
            mstr = KConf.SETTINGS:f_enable("show_current_pos")
            if imgui.MenuItem(mstr .. " Position Display") then
                KConf.SETTINGS:toggle("show_current_pos")
            end
            mstr = KConf.SETTINGS:f_enable("debug")
            if imgui.MenuItem(mstr .. " Debugging") then
                KConf.SETTINGS:toggle("debug")
            end
            if imgui.MenuItem("Clear") then
                g_messages = {}
            end
            if imgui.MenuItem("Close") then
                KConf.SETTINGS:set("enable", false)
                imgui.SetWindowFocus(nil)
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Temples") then
            for _, tdef in ipairs(POI.Temples) do
                _add_menu_item(tdef:as_poi())
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Orbs") then
            for _, odef in pairs(POI.Orbs) do
                _add_menu_item(odef:as_poi())
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Bosses") then
            for _, boss in ipairs(POI.BOSSES) do
                _add_menu_item(boss)
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Places") then
            for _, place in ipairs(POI.PLACES) do
                _add_menu_item(place)
            end
            imgui.EndMenu()
        end
        --[[ TODO: Saved waypoints
        if imgui.BeginMenu("Waypoints") then
            imgui.EndMenu()
        end
        ]]
        imgui.EndMenuBar()
    end
end

function _build_gui()
    local player = get_players()[1]

    local curr_abs_x, curr_abs_y = get_player_pos(player)
    if curr_abs_x == nil or curr_abs_y == nil then
        --[[ We could be building the GUI before the player is initialized ]]
        return nil
    end
    local curr_rel_x, curr_rel_y, curr_world = pos_abs_to_rel(curr_abs_x, curr_abs_y)

    if KConf.SETTINGS:get("show_current_pos") then
        local show_x = curr_rel_x
        local show_y = curr_rel_y
        local show_world = curr_world
        if input_relative then
            show_x = curr_abs_x
            show_y = curr_abs_y
            show_world = 0
        end
        imgui.Text(("%.2f %.2f %d"):format(show_x, show_y, show_world))
    end

    -- Configured: input_{x,y,world}
    -- Current: curr_abs_{x,y} curr_rel_{x,y,world}
    -- Prior: save_{x,y,world}
    ret, input_x, input_y = imgui.InputFloat2("X,Y", input_x, input_y)
    imgui.SameLine()
    ret, input_world = imgui.InputInt("World", input_world)
    ret, input_relative = imgui.Checkbox("Relative", input_relative)

    --[[ TODO: Waypoint name input ]]

    if imgui.Button("Get Position") then
        local plr_x, plr_y = get_player_pos(player)
        input_x, input_y, input_world = pos_abs_to_rel(plr_x, plr_y)
    end

    imgui.SameLine()
    if imgui.Button("Teleport") or g_teleport_now then
        g_teleport_now = false
        warp_to{player,
            x = input_x,
            y = input_y,
            world = input_world,
            add = input_relative
        }
    end

    --[[ TODO: Buttons to save and remove saved waypoints
    if imgui.Button("Store Position") then
    end

    if imgui.Button("Remove Saved Position") then
    end
    ]]

    imgui.SameLine()
    if imgui.Button("Go West") then
        warp_to{player,
            world = curr_world - 1
        }
    end

    imgui.SameLine()
    if imgui.Button("Go East") then
        warp_to{player,
            world = curr_world + 1
        }
    end

    if curr_world ~= 0 then
        imgui.SameLine()
        if imgui.Button("Go Main World") then
            warp_to{player,
                world = 0
            }
        end
    end

    --[[if imgui.Button("Save Position") then
        save_player_pos(player)
    end]]

    if save_x ~= nil and save_y ~= nil and save_world ~= nil then
        if imgui.Button("Teleport Back") then
            warp_to{player,
                x = save_x,
                y = save_y,
                world = save_world,
                returning = true
            }
        end
    end

    for index, entry in ipairs(g_messages) do
        if type(entry) == "table" then
            for j, msg in ipairs(entry) do
                imgui.Text(msg)
            end
        else
            imgui.Text(entry)
        end
    end
    return true

end

function _do_post_update()
    local window_flags = imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.MenuBar
    if KConf.SETTINGS:get("enable") then
        --[[ Determine if we need to update anything ]]
        local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
        if newgame_n ~= g_save_ng or #POI.Orbs == 0 or #POI.Temples == 0 then
            debug_msg(("Forcing update; NG %d->%d, %d orbs, %d temples"):format(
                g_save_ng, newgame_n, #POI.Orbs, #POI.Temples))
            g_force_update = true
            g_save_ng = newgame_n
        end

        --[[ If we need to update anything, update everything ]]
        if g_force_update then
            POI.Orbs = {}
            POI.init_orb_list(POI.Orbs)
            debug_msg("Orbs updated")
            POI.Temples = {}
            POI.init_temple_list(POI.Temples)
            debug_msg("Temples updated")
        end

        --[[ Determine where Toveri is ]]
        if not g_toveri_updated then
            local cave_idx = deduce_toveri_cave()
            local tpos = update_toveri_cave(cave_idx)
            g_toveri_updated = true
            debug_msg(("Toveri cave updated; index %d x=%d y=%d"):format(
                cave_idx, tpos[1], tpos[2]))
        end

        if imgui.Begin("Waypoints", nil, window_flags) then
            _build_menu_bar_gui()
            _build_gui()
            imgui.End()
        end
    end
end

function OnWorldInitialized()
    g_force_update = true
end

function OnModPostInit()
    imgui = load_imgui({version="1.0.0", mod="kae_waypoint"})
end

function OnPlayerSpawned(player_entity)
    g_force_update = true
end

function OnWorldPostUpdate()
    if imgui == nil then
        OnModPostInit()
    end
    local status, result = xpcall(_do_post_update, on_error)
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
