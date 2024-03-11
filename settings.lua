dofile("data/scripts/lib/utilities.lua")
dofile("data/scripts/lib/mod_settings.lua")

KConf = dofile_once("mods/kae_waypoint/config.lua")

-- Available functions:
-- ModSettingSetNextValue(setting_id, next_value, is_default)
-- ModSettingSet(setting_id, new_value)

-- Available if desired
--function mod_setting_changed_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
--end

mod_settings_version = 1
mod_settings = {
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Uncheck this to hide the UI",
        value_default = KConf.SETTINGS.enable.default,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "text_size",
        ui_name = "Input Buffer Size",
        ui_description = "",
        value_default = KConf.SETTINGS.text_size.default,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "show_current_pos",
        ui_name = "Show Position",
        ui_description = "Display the player's current position",
        ui_default = KConf.SETTINGS.show_current_pos.default,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "quick_teleport",
        ui_name = "Instant Teleport",
        ui_description = "Teleport instantly upon selecting a target",
        ui_default = KConf.SETTINGS.quick_teleport.default,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "debug",
        ui_name = "Enable Debugging",
        ui_description = "Enable debugging output",
        value_default = KConf.SETTINGS.debug.default,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(KConf.MOD_ID)
    mod_settings_update(KConf.MOD_ID, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(KConf.MOD_ID, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(KConf.MOD_ID, mod_settings, gui, in_main_menu)
end

-- vim: set ts=4 sts=4 sw=4:
