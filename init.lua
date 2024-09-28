--[[ Waypoints and Teleport
--
-- This mod provides numerous teleport destinations to things of interest:
--  Orbs (all 11 standard)
--  Bosses
--  Places of interest
--  Temples
--  Hidden eye glyphs (with Disable Mod Restrictions)
--
-- Key features include:
--  Correct Orb locations for NG and NG+
--  Correct identification of Toveri's cave
--  Identification of collapsed temples (only works in NG)
--  Live tracking of player position
--]]

--[[ TODO:
-- Allow for selectively removing modded places.
-- Warp history.
--
-- Allow teleporting by clicking on a biome map
--  BiomeMapConvertPixelFromUintToInt to get color, possibly?
--]]

dofile_once("data/scripts/lib/utilities.lua")
KConf = dofile_once("mods/kae_waypoint/files/config.lua")
dofile_once("mods/kae_waypoint/files/poi.lua")
I18N = dofile_once("mods/kae_waypoint/files/i18n.lua")
smallfolk = dofile_once("mods/kae_waypoint/files/lib/smallfolk.lua")

--[[ ModSettingSet(CONF_SAVE_KEY, value) to add custom waypoints ]]
CONF_SAVE_KEY = MOD_ID .. "." .. "_places"

--[[ GlobslSetValue(FORCE_UPDATE_KEY, "1") to force update ]]
FORCE_UPDATE_KEY = MOD_ID .. "_force_update"

local imgui
local g_messages = {}           -- lines being drawn
local g_force_update = true     -- trigger a POI recalculation
local g_toveri_updated = false  -- did we determine Toveri's location?
local g_teleport_now = false    -- don't just load the POI; teleport to it
local g_save_ng = 0             -- cached NG+ count
local g_extra_poi = {}          -- places defined by other mods

--[[ Inputs to the main GUI. Global so other functions can update them. ]]
local input_x = 0
local input_y = 0
local input_world = 0
local input_relative = false

--[[ Player coordinates prior to the warp, for optional return later ]]
local save_x, save_y, save_world = nil, nil, nil

--[[ Do the two messages match? ]]
function compare_msg(msg1, msg2)
    if type(msg1) == "string" and type(msg2) == "string" then
        return msg1 == msg2
    end
    if type(msg1) == "table" and type(msg2) == "table" then
        local line1 = table.concat(msg1, " ")
        local line2 = table.concat(msg2, " ")
        return line1 == line2
    end
    return tostring(msg1) == tostring(msg2)
end

--[[ Add a message to the top of the output list ]]
function add_msg(msg)
    table.insert(g_messages, 1, msg)
end

--[[ Add a message, unless it was just added ]]
function add_last_msg(msg)
    if #g_messages == 0 or not compare_msg(g_messages[1], msg) then
        add_msg(msg)
        print(("%s: %s"):format(MOD_ID, msg))
    end
end

--[[ Add a message, unless it was ever added ]]
function add_unique_msg(msg)
    for _, message in ipairs(g_messages) do
        if compare_msg(message, msg) then
            return
        end
    end
    add_msg(msg)
end

--[[ Add a debugging message ]]
function debug_msg(msg)
    if KConf.SETTINGS:get("debug") then
        add_last_msg("DEBUG: " .. msg)
    end
end

--[[ Called on error caught by xpcall ]]
function on_error(arg)
    GamePrint(tostring(arg))
    add_msg(arg)
    print_error(arg)
    if debug and debug.traceback then
        add_msg(debug.traceback())
    else
        print_error("Generating traceback...")
        SetPlayerSpawnLocation()
    end
end

--[[ value == nil ? nilvalue : value ]]
function nil_or(value, nilvalue)
    if value == nil then
        return nilvalue
    end
    return value
end

--[[ The world size can vary between NG and NG+ ]]
function get_world_width()
    return BiomeMapGetSize() * 512
end

--[[ Get the absolute position of the player ]]
function get_player_pos(player)
    local px, py = EntityGetTransform(player)
    return px, py
end

--[[ Decompose absolute [x, y] into [x, y, world offset] ]]
function pos_abs_to_rel(px, py)
    local pw, mx = check_parallel_pos(px)
    return mx, py, pw
end

--[[ Compose [x, y, world offset] into absolute [x, y] ]]
function pos_rel_to_abs(px, py, world)
    local x_adj = get_world_width() * world
    return px + x_adj, py
end

--[[ Get the current position of the player, relative to the current world ]]
function get_current_pos()
    local px, py = get_player_pos(get_players()[1])
    if not px or not py then return nil, nil, nil end
    local wx, wy, wnum = pos_abs_to_rel(px, py)
    return wx, wy, wnum
end

--[[ Warp the player to the given coordinates ]]
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
        -- Coordinates are declared relative
        arg_x = plr_x + nil_or(args.x, 0)
        arg_y = plr_y + nil_or(args.y, 0)
        arg_world = plr_world + nil_or(args.world, 0)
    elseif args.world == nil then
        -- No world -> coordinates are absolute
        arg_x = nil_or(args.x, abs_x)
        arg_y = nil_or(args.y, abs_y)
        arg_x, arg_y, arg_world = pos_abs_to_rel(arg_x, arg_y)
    else
        -- Has world -> coordinates are relative
        arg_x = nil_or(args.x, plr_x)
        arg_y = nil_or(args.y, plr_y)
        arg_world = args.world
    end

    local final_x, final_y = pos_rel_to_abs(arg_x, arg_y, arg_world)
    debug_msg(("Warp to [%.02f, %.02f] in PW %d (%.02f, %.02f)"):format(
        arg_x, arg_y, arg_world, final_x, final_y))

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

    -- Allow for locations to provide custom logic (see README.md)
    if type(item.refine_fn) == "function" then
        local new_x, new_y, new_world = item.refine_fn(item)
        debug_msg(("Refined POI to %s,%s,%s"):format(new_x, new_y, new_world))
        if new_x ~= nil then target_x = new_x end
        if new_y ~= nil then target_y = new_y end
        if new_world ~= nil then target_world = new_world end
    end

    if target_x == nil or target_y == nil then
        add_msg(("Invalid waypoint %s"):format(name))
        return
    end

    -- Load the values into the input variables
    input_x = target_x
    input_y = target_y
    input_world = target_world
    if KConf.SETTINGS:get("quick_teleport") then
        g_teleport_now = true
    end
end

--[[ Merge any locations defined via mod settings ]]
-- TODO: Support {group=string}
-- TODO: Deduplicate among new entries to prevent repeated additions
function load_poi_config()
    local data = ModSettingGet(CONF_SAVE_KEY)
    local new_data = ModSettingGetNextValue(CONF_SAVE_KEY)
    if new_data ~= nil and data ~= new_data then
        -- Persist new_data to data
        ModSettingSet(CONF_SAVE_KEY, new_data)
        data = new_data
    end

    local new_places = {}
    if data ~= nil then
        local entries = smallfolk.loads(data)
        debug_msg(("Loaded %d entries from %s"):format(#entries, data))
        for _, entry in ipairs(entries) do
            if not is_valid_poi(entry) then
                debug_msg(("Malformed entry %s"):format(smallfolk.dumps(entry)))
            elseif is_duplicate_poi(entry) then
                debug_msg(("Duplicate entry %s"):format(smallfolk.dumps(entry)))
            else
                debug_msg(("Adding entry %s"):format(smallfolk.dumps(entry)))
                _add_poi_to(new_places, entry)
            end
        end
    end
    return new_places
end

--[[ Add a POI to the given table ]]
function _add_poi_to(places, entry)
    local new_poi = create_poi(entry)

    if entry.group then
        -- Determine if the group already exists
        local found_poi = false
        for idx, poi in ipairs(places) do
            if poi[1] == entry.group then
                found_poi = true
                if not poi.l then
                    -- It's a lone POI; convert it to a group
                    poi.l = {{poi[1], poi[2]}}
                end
                table.insert(poi.l, new_poi)
                break
            end
        end
        if not found_poi then
            -- It's a new group
            table.insert(places, {entry.group, l={new_poi}})
        end
    else
        table.insert(places, new_poi)
    end
end

--[[ Draw a hover message ]]
function _draw_hover(content)
    if imgui.IsItemHovered() then
        if imgui.BeginTooltip() then
            if type(content) == "function" then
                content()
            else
                imgui.Text(tostring(content))
            end
            imgui.EndTooltip()
        end
    end
end

function _add_menu_item(item)
    local label_raw = item[1]
    if type(item.label_fn) == "function" then
        label_raw = item.label_fn(item)
    end

    local label = I18N.localize(label_raw, true)

    if type(item.filter_fn) == "function" then
        if not item.filter_fn(item) then
            return
        end
    end

    if item.l ~= nil then
        -- It's a nested item
        if imgui.BeginMenu(label) then
            for _, sub_item in pairs(item.l) do
                _add_menu_item(sub_item)
            end
            imgui.EndMenu()
        end
        if item.hover then
            _draw_hover(item.hover:gsub("%$[a-z0-9_]+", GameTextGetTranslatedOrNot))
        end
    else
        -- Nested items can't have coordinates of their own
        local pos = item[2] or {}
        if #pos < 2 then
            label = label .. " [TODO]"
        end
        if imgui.MenuItem(label) then
            local new_poi = {label, pos}
            if item.refine_fn then new_poi.refine_fn = item.refine_fn end
            load_waypoint(new_poi)
            local xpos, ypos, wpos = pos_abs_to_rel(pos[1], pos[2])
            add_msg({
                ("Loaded waypoint %q"):format(label),
                pos = {x=xpos, y=ypos, world=wpos}
            })
        end
        if item.hover then
            _draw_hover(item.hover:gsub("%$[a-z0-9_]+", GameTextGetTranslatedOrNot))
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
            if imgui.MenuItem("Delete Modded Places") then
                ModSettingSetNextValue(CONF_SAVE_KEY, "{}", false)
                add_msg({"Deleted all locations added by mods", color={1, 0.25, 0.25}})
                g_force_update = true
            end
            if imgui.MenuItem("Close") then
                KConf.SETTINGS:set("enable", false)
                imgui.SetWindowFocus(nil)
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Temples") then
            for _, tdef in ipairs(Temples) do
                _add_menu_item(tdef:as_poi())
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Orbs") then
            for _, odef in pairs(Orbs) do
                _add_menu_item(odef:as_poi())
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Bosses") then
            for _, boss in ipairs(BOSSES) do
                _add_menu_item(boss)
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Places") then
            for _, place in ipairs(PLACES) do
                _add_menu_item(place)
            end
            imgui.EndMenu()
        end
        if #g_extra_poi > 0 then
            if imgui.BeginMenu("Mod Places") then
                for _, place in ipairs(g_extra_poi) do
                    _add_menu_item(place)
                end
                imgui.EndMenu()
            end
        end
        imgui.EndMenuBar()
    end
end

function _build_gui()
    local player = get_players()[1]
    if not player or player == 0 then
        --[[ Player entity not available ]]
        return nil
    end

    local curr_abs_x, curr_abs_y = get_player_pos(player)
    if curr_abs_x == nil or curr_abs_y == nil then
        --[[ We could be building the GUI before the player is initialized ]]
        return nil
    end
    local curr_rel_x, curr_rel_y, curr_world = pos_abs_to_rel(curr_abs_x, curr_abs_y)

    -- Always display current position in the GUI
    local show_x = curr_rel_x
    local show_y = curr_rel_y
    local show_world = curr_world
    if input_relative then
        show_x = curr_abs_x
        show_y = curr_abs_y
        show_world = 0
    end
    imgui.Text(("%.2f %.2f %d"):format(show_x, show_y, show_world))

    -- Configured: input_{x,y,world}
    -- Current: curr_abs_{x,y} curr_rel_{x,y,world}
    -- Prior: save_{x,y,world}
    imgui.SetNextItemWidth(200)
    ret, input_x, input_y = imgui.InputFloat2("X,Y", input_x, input_y)
    imgui.SameLine()
    imgui.SetNextItemWidth(100)
    ret, input_world = imgui.InputInt("World", input_world)
    ret, input_relative = imgui.Checkbox("Relative", input_relative)
    if ret then
        if input_relative then
            input_x = input_x - curr_abs_x
            input_y = input_y - curr_abs_y
        else
            input_x = input_x + curr_abs_x
            input_y = input_y + curr_abs_y
        end
    end

    if #g_messages > 0 then
        imgui.SameLine()
        if imgui.SmallButton("Clear") then
            g_messages = {}
        end
        _draw_hover("Clear the teleport log below")
    end

    imgui.SameLine()
    if imgui.SmallButton("Get Position") then
        local plr_x, plr_y = get_player_pos(player)
        input_x, input_y, input_world = pos_abs_to_rel(plr_x, plr_y)
        add_msg({
            ("Got %d, %d, world %d"):format(input_x, input_y, input_world),
            pos = {x=input_x, y=input_y, world=input_world},
            biome = BiomeMapGetName(input_x, input_y),
        })
    end
    _draw_hover("Save your current position")

    if imgui.Button("Teleport") or g_teleport_now then
        g_teleport_now = false
        warp_to{player,
            x = input_x,
            y = input_y,
            world = input_world,
            add = input_relative
        }
    end

    imgui.SameLine()
    if imgui.Button("Go West") then
        warp_to{player,
            world = curr_world - 1,
            returning = true
        }
    end
    _draw_hover("Teleport to the west parallel world, at your current location")

    imgui.SameLine()
    if imgui.Button("Go East") then
        warp_to{player,
            world = curr_world + 1,
            returning = true
        }
    end
    _draw_hover("Teleport to the east parallel world, at your current location")

    if curr_world ~= 0 then
        imgui.SameLine()
        if imgui.Button("Go Main World") then
            warp_to{player,
                world = 0,
                returning = true
            }
        end
        _draw_hover("Return to the main (central) world")
    end

    local same_line = false
    if save_x ~= nil and save_y ~= nil and save_world ~= nil then
        if imgui.Button("Teleport Back") then
            warp_to{player,
                x = save_x,
                y = save_y,
                world = save_world,
                returning = true
            }
        end
        _draw_hover("Return to the previous location you were before teleporting")
        same_line = true
    end

    if player_in_temple() then
        if same_line then
            imgui.SameLine()
        end
        if imgui.Button("Leave Temple") then
            local tx, ty = temple_get_exit()
            local biome = BiomeMapGetName(tx, ty + 100)
            if not biome or biome == "" or biome == "_EMPTY_" then
                biome = "<unknown biome>"
            else
                biome = GameTextGetTranslatedOrNot(biome)
            end
            add_msg({
                ("Left temple into %s"):format(biome),
                pos = {x=curr_abs_x, y=curr_abs_y}
            })
            warp_to{player,
                x = tx,
                y = ty
            }
        end
        _draw_hover("Leave the temple you're currently in")
    end

    -- Ensure the controls are visible
    if not imgui.IsWindowCollapsed() then
        local wix, wiy = imgui.GetWindowSize()
        local avx, avy = imgui.GetContentRegionAvail()
        if avy < 0 then
            imgui.SetWindowSize(wix, wiy-avy)
        end
    end

    for _, entry in ipairs(g_messages) do
        _draw_line(entry)
    end
    return true
end

function _draw_line(line)
    if type(line) == "string" then
        imgui.Text(line)
        return
    end

    if type(line) ~= "table" then
        imgui.Text(tostring(line))
        return
    end

    if line.color then
        if type(line.color) == "string" then
            line.color = lookup_color(line.color)
        end
        imgui.PushStyleColor(imgui.Col.Text, unpack(line.color))
    end

    if line.pos and line.pos.x and line.pos.y then
        local bid = ("%d_%d"):format(line.pos.x, line.pos.y)
        if imgui.SmallButton("Return###" .. bid) then
            debug_msg(("Return %s"):format(smallfolk.dumps(line.pos)))
            local player = line.pos.player or get_players()[1]
            local xpos, ypos = line.pos.x, line.pos.y
            local wpos = line.pos.world or 0
            warp_to{get_players()[1],
                x = xpos,
                y = ypos,
                world = wpos,
                returning = true
            }
        end
        imgui.SameLine()
        local biome = line.biome or BiomeMapGetName(line.pos.x, line.pos.y)
        if biome ~= "_EMPTY_" then
            imgui.Text(("[%s]"):format(GameTextGet(biome)))
            imgui.SameLine()
        end
    end
    for idx, token in ipairs(line) do
        if idx ~= 1 then imgui.SameLine() end
        _draw_line(token)
    end

    if line.color then
        imgui.PopStyleColor()
    end
end

function _do_post_update()
    if KConf.SETTINGS:get("enable") then
        local window_flags = bit.bor(
            imgui.WindowFlags.NoFocusOnAppearing,
            imgui.WindowFlags.HorizontalScrollbar,
            imgui.WindowFlags.NoNavFocus,
            imgui.WindowFlags.MenuBar)

        --[[ Determine if we need to update anything ]]
        local newgame_n = tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT"))
        if newgame_n ~= g_save_ng or #Orbs == 0 or #Temples == 0 then
            debug_msg(("Forcing update; NG %d->%d, %d orbs, %d temples"):format(
                g_save_ng, newgame_n, #Orbs, #Temples))
            g_force_update = true
            g_save_ng = newgame_n
        end

        if GlobalsGetValue(FORCE_UPDATE_KEY, "0") ~= "0" then
            GlobalsSetValue(FORCE_UPDATE_KEY, "0")
            g_force_update = true
        end

        --[[ If we need to update anything, update everything ]]
        if g_force_update then
            Orbs = {}
            init_orb_list(Orbs)
            debug_msg("Orbs updated")
            Temples = {}
            init_temple_list(Temples)
            debug_msg("Temples updated")
            update_eye_locations()
            debug_msg("Eye Glyph locations updated")
            g_extra_poi = load_poi_config()
            debug_msg("Loaded extra locations")
            g_force_update = false
        end

        --[[ Determine where Toveri is ]]
        if not g_toveri_updated then
            -- luacheck: globals deduce_toveri_cave update_toveri_cave
            local cave_idx = deduce_toveri_cave()
            local tpos = update_toveri_cave(cave_idx)
            g_toveri_updated = true
            debug_msg(("Toveri cave updated; index %d x=%d y=%d"):format(
                cave_idx, tpos[1], tpos[2]))
        end

        title = "Teleport"
        if KConf.SETTINGS:get("show_current_pos") then
            local plrx, plry, plrw = get_current_pos()
            if plrx ~= nil and plry ~= nil then
                local pos_str = ("%d, %d"):format(plrx, plry)
                if plrw ~= 0 then
                    pos_str = ("%d, %d world %d"):format(plrx, plry, plrw)
                end
                title = ("%s: %s"):format(title, pos_str)
            end
        end
        if KConf.SETTINGS:get("show_current_biome") then
            local player = get_players()[1]
            local plrx, plry = get_player_pos(player)
            if plrx ~= nil and plry ~= nil then
                local biome = BiomeMapGetName(plrx, plry)
                if biome ~= "_EMPTY_" then
                    title = ("%s: %s"):format(title, GameTextGet(biome))
                end
            end
        end
        if imgui.Begin(("%s###Teleport"):format(title), nil, window_flags) then
            _build_menu_bar_gui()
            _build_gui()
            imgui.End()
        end
    end
end

function OnModPostInit()
    if load_imgui then
        imgui = load_imgui({version="1.0.0", mod="kae_waypoint"})
    end
end

function OnWorldInitialized()
    g_force_update = true
end

function OnPlayerSpawned(player_entity)
    g_force_update = true
end

function OnWorldPostUpdate()
    if imgui == nil then
        OnModPostInit()
    end

    if imgui ~= nil then
        local status, result = xpcall(_do_post_update, on_error)
        if not status then
            GamePrint(("%s: _do_post_update failed with %s"):format(MOD_ID, result))
            print_error(("%s: _do_post_update failed with %s"):format(MOD_ID, result))
        end
    else
        GamePrint("kae_waypoint - imgui not found; see workshop page for instructions")
    end
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
