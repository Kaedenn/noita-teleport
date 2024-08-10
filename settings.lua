dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

-- Available functions:
-- ModSettingSetNextValue(setting_id, next_value, is_default)
-- ModSettingSet(setting_id, new_value)

-- Available if desired
--function mod_setting_changed_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
--end

MOD_ID = "kae_waypoint"
mod_settings_version = 2
mod_settings = {
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Uncheck this to hide the UI",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "show_current_pos",
        ui_name = "Show Position",
        ui_description = "Display the player's current position",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "show_current_biome",
        ui_name = "Show Biome",
        ui_description = "Show the name of the current biome, if there is one",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "quick_teleport",
        ui_name = "Instant Teleport",
        ui_description = "Teleport instantly upon selecting a target",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "debug",
        ui_name = "Enable Debugging",
        ui_description = "Enable debugging output",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(MOD_ID)
    mod_settings_update(MOD_ID, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(MOD_ID, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(MOD_ID, mod_settings, gui, in_main_menu)
end

-- vim: set ts=4 sts=4 sw=4:
