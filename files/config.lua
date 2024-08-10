dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

MOD_ID = "kae_waypoint"

SETTINGS = setmetatable({
    ENABLE = {          -- should we draw the UI?
        name = "enable",
        default = true,
    },
    SHOW_CURRENT_POS = { -- should we display the current player position?
        name = "show_current_pos",
        default = true,
    },
    SHOW_CURRENT_BIOME = { -- should we display the current biome?
        name = "show_current_biome",
        default = true,
    },
    QUICK_TELEPORT = {  -- should we teleport immediately after selecting a POI?
        name = "quick_teleport",
        default = false,
    },
    DEBUG = {           -- should we output debug messages?
        name = "debug",
        default = false,
    },

    -- Get a table of all setting keys
    all = function(self)
        local keys = {}
        for key, def in pairs(self) do
            if key == key:upper() then
                table.insert(keys, key)
            end
        end
        return keys
    end,

    -- True if the setting exists, false otherwise
    has = function(self, key)
        if self[key:upper()] ~= nil then
            return true
        end
        return false
    end,

    -- Obtain the current value. Returns nil if the setting doesn't exist.
    get = function(self, key)
        if self:has(key) then
            local conf = MOD_ID .. "." .. key:lower()
            return ModSettingGet(conf)
        end
        return nil
    end,

    -- Update the setting. Returns true on success, false on error.
    set = function(self, key, value)
        if self:has(key) then
            local conf = MOD_ID .. "." .. key:lower()
            ModSettingSetNextValue(conf, value, false)
        end
    end,

    -- Toggle a boolean setting
    toggle = function(self, key)
        if self:has(key) then
            self:set(key, not self:get(key))
        end
    end,

    -- "Enable" or "Disable" depending on setting value
    f_enable = function(self, key)
        if self:has(key) then
            if self:get(key) then
                return "Disable"
            end
        end
        return "Enable"
    end,
}, {
    __index = function(self, key)
        return rawget(self, key:upper())
    end
})

-- Add get/set functions to the settings themselves
local function _init_once()
    for _, name in ipairs(SETTINGS:all()) do
        SETTINGS[name].get = function(self)
            return SETTINGS:get(name)
        end
        SETTINGS[name].set = function(self, value)
            return SETTINGS:set(name, value)
        end
    end
end
_init_once()

return {
    MOD_ID = MOD_ID,
    SETTINGS = SETTINGS,
    get = function(setting) return SETTINGS:get(setting) end,
    set = function(setting, value) SETTINGS:set(setting, value) end,
}

-- vim: set ts=4 sts=4 sw=4:
